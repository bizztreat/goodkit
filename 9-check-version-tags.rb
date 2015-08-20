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

start = options[:start]
#devel = options[:devel]
#start = 'x1c6gsmxhr84usnhww03s6ecx3625279'
#devel = 't3m4hv0v5vrysctjqax88t2q2346t6vd'

#testing master project ID = y672cuxov5x6swn64tlaz5jwcrez0wid

puts 'Connecting to GoodData...'
puts 'Checking missing version tag'

GoodData.with_connection(username, password) do |client|
    
    GoodData.with_project(start) do |project|
        
        puts "Printing reports without version tag..."
        
        project.reports.each do |report|
            
                tags = report.tags.gsub(/\s+/m, ' ').strip.split(" ")
                if
                !tags.any? { |tag| /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/.match(tag) }
                then puts 'https://secure.gooddata.com' + report.uri
                end

        end
        
        puts "Printing metrics without version tag..."
        
        project.metrics.each do |metric|
        
            tags = metric.tags.gsub(/\s+/m, ' ').strip.split(" ")
            if
                !tags.any? { |tag| /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/.match(tag) }
                then puts 'https://secure.gooddata.com' + metric.uri
            end
        
        end
        
    end
    
end

puts 'Disconnecting...'
GoodData.disconnect
