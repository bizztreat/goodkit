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

end.parse!

# get credentials from input parameters
username = options[:username]
password = options[:password]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# change the tags to check here
tag = ['qa','test']

puts 'Connecting to GoodData...'
puts 'Testing Report results between Start and Devel projects.'

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|

       # get the project context using Project ID from user input
       devel = client.projects(options[:devel])
       
       # for each tag
       tag.each do |tag|
       
       # get metrics that include specific tag
       metrics = devel.metrics.select {|r| r.tag_set.include?(tag)}
       
       # print metric result
       metrics.each { |m| puts m.title + ' : ' + m.execute.to_s }
       
       end

end

puts 'Disconnecting...'
GoodData.disconnect
