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
    
end.parse!

#username = ''
#password = ''
username = options[:username]
password = options[:password]

#start = options[:start]
devel = options[:devel]
#start = 'x1c6gsmxhr84usnhww03s6ecx3625279'
#devel = 'wjvvna1eukc92gechtxlm7blcv22gsow'

#testing master project ID = y672cuxov5x6swn64tlaz5jwcrez0wid

puts 'Connecting to GoodData...'
puts 'Checking dashboard tabs with missing Google Analytics'

GoodData.with_connection(username, password) do |client|
    
    GoodData.with_project(devel) do |project|
        
        puts "Printing Dashboard tabs without GA tracking code..."
        
        count_dshb = 0
        count_tabs = 0
        
        project.dashboards.each do |dshb|
                count_dshb += 1
                dshb.tabs.each do |tab|
                    
                        count_tabs += 1
                        
                        if
                        !tab.items.to_s.include? "https://demo.zoomint.com/stat/%CURRENT_DASHBOARD_URI%/%CURRENT_DASHBOARD_TAB_URI%"
                        then
                        
                        puts 'https://secure.gooddata.com/#s=/gdc/projects/' + devel + '|projectDashboardPage|' + dshb.uri + '|' + tab.identifier

                        end
                    
                end

        end
        
        puts "Totally checked #{count_tabs} Tabs on #{count_dshb} Dashboards."
        
    end
    
end

puts 'Disconnecting...'
GoodData.disconnect
