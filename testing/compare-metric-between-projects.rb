#Testing Metric results between Start and Devel projects.
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
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
    # change the tags to check here. Use this format only!:['tag1','tag2'] for example:['qa','test'] 
    opts.on('-t', '--tags TAGS', 'Tags') { |v| options[:tags] = v }

end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]
server = options[:server]
start = client.projects(options[:start])
devel = client.projects(options[:devel])
tag = client.projects(options[:tags])

# variables for script results
result_array = []
$result = []

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# turn off GoodData logging
GoodData.logging_off

# connect to gooddata project
GoodData.with_connection(login: username, password: password, server: server) do |client|
    
    
       start_project = client.projects(start)
       devel_project = client.projects(devel)
       # for each tag
       tag.each do |tag|
       
       # get metric from start project
       orig_metrics = start_project.metrics.select {|r| r.tag_set.include?(tag)}.sort_by(&:uri)
       
       # get metrics from devel project
       new_metrics = devel_project.metrics.select {|r| r.tag_set.include?(tag)}.sort_by(&:uri)

       # compare results
       results = orig_metrics.zip(new_metrics).pmap do |metrics|
           # compute both metrics and add the metrics at the end for being able to print a metric later
           metrics.map(&:execute) + [metrics.last]
       end
       
       # print results for both metrics from start and devel
       results.map do |res|
           orig_result, new_result, new_metrics = res           
           
         result_array.push(error_details = {
                               :type => "INFO",
                               :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + new_metrics.uri ,
                               :api => server + new_metrics.uri,
                               :message => 'Results of the metric ('+ new_metrics.title + ') are in both projects equal.'
                               })
           
           
       end
       
       end

    #save errors in the result variable
    $result.push({:section => 'Metric results between Start and Devel projects.', :OK => 0, :ERROR => 0, :output => result_array})
    
end

#print out the result
puts $result.to_json


GoodData.disconnect
