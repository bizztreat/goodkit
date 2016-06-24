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
  opts.on('-s', '--start_project ID', 'Start Project') { |v| options[:start_project] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
start_project = options[:start_project]
development_project = options[:development_project]
server = options[:server]

# variables for standard output
counter_ok = 0
counter_error = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# specify aggregations functions to check
aggregations = [:sum, :avg, :median, :min, :max]

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development and start GoodData projects
start_project = client.projects(start_project)
development_project = client.projects(development_project)

# compute the aggregations for all facts in start project
start_facts_results = {}
start_project.facts.each do |fact|
  aggregations.each do |aggregation|
    metric = fact.create_metric(:title => fact.uri, :type => aggregation)
    result = metric.execute
    start_facts_results[fact.uri] = result
  end
end

# compute the aggregations for all facts in development project
development_facts_results = {}
development_project.facts.each do |fact|
  aggregations.each do |aggregation|
    metric = fact.create_metric(:title => fact.uri, :type => aggregation)
    result = metric.execute
    development_facts_results[fact.uri] = result
  end
end

# compare results between projects
development_facts_results.each do |key, _|
  if start_facts_results[key] != development_facts_results[key]
    output.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|objectPage|' + key.to_s,
        :api => server + key.to_s,
        :title => start_project.metrics(key.to_s).title,
        :description => 'Aggregation is different'
    })
    counter_error += 1
  else
    counter_ok += 1
  end
end

$result.push({:section => 'Compare aggregations between start and devel project', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
