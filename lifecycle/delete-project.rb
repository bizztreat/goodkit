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
  opts.on('-d', '--project_id ID', 'Project Id') { |v| options[:project_id] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials from input parameters
username = options[:username]
password = options[:password]
server = options[:server]
project_id = options[:project_id]

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|

  # get the project context using Project ID from user input
  project = client.projects(project_id)
  project.delete

  $result.push({:section => 'Delete Project', :ERROR => 0})
  puts $result.to_json

end

GoodData.disconnect
