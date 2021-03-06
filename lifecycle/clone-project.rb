require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|
  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--project_id ID', 'Project Id') { |v| options[:project_id] = v }
  opts.on('-n', '--new_project_name NAME', 'New Project Name') { |v| options[:new_project_name] = v }
  opts.on('-a', '--auth_token TOKEN', 'Authorization Token') { |v| options[:auth_token] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
project_id = options[:project_id]
new_project_name = options[:new_project_name]
auth_token = options[:auth_token]

$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to GoodData project
project = client.projects(project_id)

cloned_project = project.clone(
    :title => new_project_name,
    :with_data => true,
    :with_users => true,
    :auth_token => auth_token
)

$result.push({:section => 'Clone Project', :OK => 1, :INFO => 0, :ERROR => 0, :output => {:project_id => cloned_project.pid}})
puts $result.to_json

client.disconnect
