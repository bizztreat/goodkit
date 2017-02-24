require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-s', '--project_to_update ID', 'Project to Update') { |v| options[:project_to_update] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
project_to_update = options[:project_to_update]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]

# variables for standard output
counter_ok = 0
counter_errors = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

client = GoodData.connect(login: username, password: password, server: server)
development_project = client.projects(development_project)
development_project_model = development_project.blueprint
project_to_update = client.projects(project_to_update)

begin
  child_model = project_to_update.blueprint
  new_model = child_model.merge(development_project_model)
  counter_ok += 1
rescue Exception => message
  output.push(details = {
      :type => 'ERROR',
      :url => '#',
      :api => '#',
      :title => message.to_s,
      :description => 'Merging two models is not possible.',
  })
  counter_errors += 1
else
  project_to_update.update_from_blueprint(new_model)
end

$result.push({:section => 'Merging models', :OK => counter_ok, :INFO => 0, :ERROR => counter_errors, :output => output})
puts $result.to_json

client.disconnect