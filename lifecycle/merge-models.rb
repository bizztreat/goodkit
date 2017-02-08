require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-u', '--project_to_update', 'Project to Update') { |v| options[:project_to_update] = v }
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

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# get development project blueprint (model)
development_project_model = development_project.blueprint

# for each customer/child project merge models
GoodData.with_project(project_to_update) do |child|

  begin
    child_model = child.blueprint
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
    child.update_from_blueprint(new_model)
  end
end

$result.push({:section => 'Merging models', :OK => counter_ok, :INFO => 0, :ERROR => counter_errors, :output => output})
puts $result.to_json

client.disconnect