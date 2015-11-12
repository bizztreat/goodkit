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

# collect parameters for connection and for project variable
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end


puts 'Connecting to GoodData...'
puts 'Checking missing version tag'

GoodData.with_connection(login: username, password: password, server: server) do |client|

    # connect to project
    GoodData.with_project(devel) do |project|
        
        puts "Printing reports without version tag..."
        
        # check all reports for missing tags
        project.reports.each do |report|
            
                tags = report.tags.gsub(/\s+/m, ' ').strip.split(" ")
                if
                !tags.any? { |tag| /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/.match(tag) }
                then puts server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + report.uri
                end

        end
        
        puts "Printing metrics without version tag..."
        
        # check all metrics for missing tags
        project.metrics.each do |metric|
        
            tags = metric.tags.gsub(/\s+/m, ' ').strip.split(" ")
            if
                !tags.any? { |tag| /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/.match(tag) }
                then puts server + '#s=/gdc/projects/' + devel + '|objectPage|' + metric.uri
            end
        
        end
        
    end
    
end

puts 'Disconnecting...'
GoodData.disconnect
