require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-s', '--start_project ID', 'Start Project') { |v| options[:start_project] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-f', '--file FILE', 'Projects file') { |v| options[:file] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
start_project = options[:start_project]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]

# variables for script results
output = []
$result = []

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development and start GoodData projects
start_project = client.projects(start_project)
development_project = client.projects(development_project)

# get development project blueprint (model)
devel_project_model = development_project.blueprint

begin
  start_project_model = start_project.blueprint
  new_model = start_project_model.merge(devel_project_model)
rescue Exception => message
  output.push(details = {
      :type => 'ERROR',
      :url => '#',
      :api => '#',
      :title => '#',
      :description => message.to_s
  })

  $result.push({:section => 'Merging two models is not possible.', :OK => 0, :INFO => 0, :ERROR => 1, :output => output})
else
  output.push(details = {
      :type => 'INFO',
      :url => '#',
      :api => '#',
      :title => '#',
      :description => 'Models have been merged successfully: ' + new_model.to_s
  })

  $result.push({:section => 'Models have been merged successfully', :OK => 1, :INFO => 0, :ERROR => 0, :output => output})
end

puts $result.to_json

client.disconnect
