require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get all parameters - username, password and project id
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

puts 'Connecting to GoodData...'
puts 'Checking dashboard tabs with missing Google Analytics'

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|
    
    # connect to project
    GoodData.with_project(devel) do |project|
        
        puts "Printing Dashboard tabs without GA tracking code..."
        
        # we will count all dashboards and tabs
        count_dshb = 0
        count_tabs = 0
        
        # for each dashboard and tab check for the URL including GA tracking code
        project.dashboards.each do |dshb|
                count_dshb += 1
                dshb.tabs.each do |tab|
                    
                        count_tabs += 1
                        
                        # check the GA tracking code
                        if
                        !tab.items.to_s.include? "https://demo.zoomint.com/stat/%CURRENT_DASHBOARD_URI%/%CURRENT_DASHBOARD_TAB_URI%"
                        then
                        
                        puts server + '/#s=/gdc/projects/' + devel + '|projectDashboardPage|' + dshb.uri + '|' + tab.identifier

                        end
                    
                end

        end
        
        # print number of tabs, dashboards that we have checked
        puts "Totally checked #{count_tabs} Tabs on #{count_dshb} Dashboards."
        
    end
    
end

puts 'Disconnecting...'
GoodData.disconnect
