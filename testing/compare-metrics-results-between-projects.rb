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
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
start_project = options[:start_project]
development_project = options[:development_project]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for script results
output = []
$result = []
counter_ok = 0

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development and start GoodData projects
start_project = client.projects(start_project)
development_project = client.projects(development_project)

# select start project metrics and include and exclude tags
start_project_metrics = start_project.metrics.select { |metric| (tags_included.empty? || !(metric.tag_set & tags_included).empty?) && (metric.tag_set & tags_excluded).empty? }.sort_by(&:title)

# select development project metrics and include and exclude tags
development_project_metrics = development_project.metrics.select { |metric| (tags_included.empty? || !(metric.tag_set & tags_included).empty?) && (metric.tag_set & tags_excluded).empty? }.sort_by(&:title)

# compare results
results = start_project_metrics.zip(development_project_metrics).pmap do |metrics|
  # compute both metrics and add the metrics at the end for being able to print a metric later
  metrics.map(&:execute) + [metrics.last] #TODO ??
end

results.map do |result|
  orig_result, new_result, new_metrics = result

  if orig_result != new_result

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + new_metrics.uri,
        :api => server + new_metrics.uri,
        :title => new_metrics.title,
        :description => 'Development metric result is different.'
    })
    counter_error += 1
  else
    counter_ok += 1
  end
end

$result.push({:section => 'Metric results between Start and Devel projects.', :OK => counter_ok, :INFO => 0, :ERROR => 0, :output => output})
puts $result.to_json

client.disconnect
