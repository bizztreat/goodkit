require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# create parameters for user input
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    
end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]

# change the tags to check here
tag = ['qa','test']

puts 'Connecting to GoodData...'
puts 'Testing Metric results between Start and Devel projects.'

# connect to gooddata project
GoodData.with_connection(username, password) do |client|
    
    
       start = client.projects(options[:start])
       devel = client.projects(options[:devel])
       
       # for each tag
       tag.each do |tag|
       
       # get metric from start project
       orig_metrics = start.metrics.select {|r| r.tag_set.include?(tag)}.sort_by(&:uri)
       
       # get metrics from devel project
       new_metrics = devel.metrics.select {|r| r.tag_set.include?(tag)}.sort_by(&:uri)

       # compare results
       results = orig_metrics.zip(new_metrics).pmap do |metrics|
           # compute both metrics and add the metrics at the end for being able to print a metric later
           metrics.map(&:execute) + [metrics.last]
       end
       
       # print results for both metrics from start and devel
       results.map do |res|
           orig_result, new_result, new_metrics = res
           puts "#{new_metrics.title}, #{orig_result == new_result}"
       end
       
       end

end

puts 'Disconnecting...'
GoodData.disconnect
