require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|
  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--project_id ID', 'Project Id') { |v| options[:project_id] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
project_id = options[:project_id]

$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

client.projects(project_id).delete

$result.push({:section => 'Delete Project', :OK => 1, :INFO => 0, :ERROR => 0})
puts $result.to_json

client.disconnect
