require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# setup all parameters for user input
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    
end.parse!

# assign to username
username = options[:username]
password = options[:password]

# specify the tags to check here
tag = ['qa','test']

puts 'Connecting to GoodData...'
puts 'Testing Report results between Start and Devel projects.'

GoodData.with_connection(username, password) do |client|
    
       # get project context for both start and devel
       start = client.projects(options[:start])
       devel = client.projects(options[:devel])
       
       # for each tag select reports, order them and compare results
       tag.each do |tag|
       
       orig_reports = start.reports.select {|r| r.tag_set.include?(tag)}.sort_by(&:title)
       
       new_reports = devel.reports.select {|r| r.tag_set.include?(tag)}.sort_by(&:title)

       results = orig_reports.zip(new_reports).pmap do |reports|
           # compute both reports and add the report at the end for being able to print a report later
           reports.map(&:execute) + [reports.last]
       end
       
       # print report name and result true/false if the result is complete
       results.map do |res|
           orig_result, new_result, new_report = res
           puts "#{new_report.title}, #{orig_result == new_result}"
       end
       
       end

end

puts 'Disconnecting...'
GoodData.disconnect
