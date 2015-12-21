require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# collect all parameters from user
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get parameters from input for conection and for project id
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

puts 'Connecting to GoodData...'
puts 'Printing out empty datasets:'

GoodData.with_connection(login: username, password: password, server: server) do |client|

   # check if any datasets is empty -> print the dataset name
   GoodData.with_project(devel) do |project|
           blueprint = project.blueprint
           blueprint.datasets.each do |dataset|
               count = dataset.count(project)
               if (count.to_i < 1) then puts dataset.title end
           end
       end
   
end

puts 'Disconnecting...'
GoodData.disconnect
