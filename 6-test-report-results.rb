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

tag = 'qa'

start = options[:start]
devel = options[:devel]
#start = 'x1c6gsmxhr84usnhww03s6ecx3625279'
#devel = 't3m4hv0v5vrysctjqax88t2q2346t6vd'

#testing master project ID = y672cuxov5x6swn64tlaz5jwcrez0wid

puts 'Connecting to GoodData...'
puts 'Testing Report results between Start and Devel projects.'

GoodData.with_connection(username, password) do |client|
    
       # We assume that reports have unique name inside a project
       orig_reports = GoodData::Report.find_by_tag(tag, client: client, project: devel).sort_by(&:title)
       new_reports = GoodData::Report.find_by_tag(tag, client: client, project: start).sort_by(&:title)
       
       results = orig_reports.zip(new_reports).pmap do |reports|
           # compute both reports and add the report at the end for being able to print a report later
           reports.map(&:execute) + [reports.last]
       end
       
       results.map do |res|
           orig_result, new_result, new_report = res
           puts "#{new_report.title}, #{orig_result == new_result}"
       end

end

puts 'Disconnecting...'
GoodData.disconnect
