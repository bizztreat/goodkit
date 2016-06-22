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
  opts.on('-d', '--project ID', 'Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-l', '--language Language', 'Language') { |v| options[:language] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server]
language = options[:language]

# counters and arrays for results
$result = []

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
project = client.projects(development_project)

development_project_metrics = []

project.metrics.each do |metric|
  development_project_metrics.push({:uri => metric.uri, :title => metric.title, :pretty_expression => metric.pretty_expression})
end

client.disconnect



