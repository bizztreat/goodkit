#Testing Report results between Start and Devel projects.
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# define options for script configuration
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-d', '--develproject NAME', 'Devel Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
    # change the tags to check here. Use this format only!:['tag1','tag2'] for example:['qa','test'] 
    opts.on('-t', '--tags TAGS', 'Tags') { |v| options[:tags] = v }
end.parse!

# get credentials from input parameters
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]
tag = tags[:server]

# variables for script results
result_array = []
$result = []

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|

       # get the project context using Project ID from user input
       devel_project = client.projects(devel)
       
       # for each tag
       tag.each do |tag|
       
       # get metrics that include specific tag
       metrics = devel_project.metrics.select {|r| r.tag_set.include?(tag)}
       
       # print metric result
       metrics.each { |m|  
       
       result_array.push(error_details = {
                               :type => "INFO",
                               :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + m.uri ,
                               :api => server + m.uri,
                               :message => 'Results of the metric ('+ m.title + ') is: ' +  m.execute.to_s
                               })
      }                         
           
    
       end
    #save errors in the result variable
    $result.push({:section => 'Metric results between Start and Devel projects.', :OK => 0, :ERROR => 0, :output => result_array})
  end

#print out the result
puts $result.to_json

GoodData.disconnect
