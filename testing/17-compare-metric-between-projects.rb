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

# change the tags to check here
tag = ['qa','test']

puts 'Connecting to GoodData...'
puts 'Testing Metric results between Start and Devel projects.'

GoodData.with_connection(username, password) do |client|
    
    
       start = client.projects(options[:start])
       devel = client.projects(options[:devel])
       #start = client.projects('ol6phugquhhn91o1ea5bwqeh9hgwwjsd')
       #devel = client.projects('x1c6gsmxhr84usnhww03s6ecx3625279')
    
       # We assume that metrics have unique name inside a project

       tag.each do |tag|
       
       orig_metrics = start.metrics.select {|r| r.tag_set.include?(tag)}.sort_by(&:uri)
       
       new_metrics = devel.metrics.select {|r| r.tag_set.include?(tag)}.sort_by(&:uri)

       results = orig_metrics.zip(new_metrics).pmap do |metrics|
           # compute both reports and add the report at the end for being able to print a report later
           metrics.map(&:execute) + [metrics.last]
       end
       
       results.map do |res|
           orig_result, new_result, new_metrics = res
           puts "#{new_metrics.title}, #{orig_result == new_result}"
       end
       
       end

end

puts 'Disconnecting...'
GoodData.disconnect
