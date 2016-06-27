#Testing Metric results between Start and Devel projects.
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# create parameters for user input
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }

end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]
server = options[:server]
start_project = options[:start_project]
development_project = options[:development_project]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for script results
result_array = []
$result = []
counter_ok = 0

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

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
  metrics.map(&:execute) + [metrics.last]
end

# print results for both metrics from start and devel
results.map do |res|
  orig_result, new_result, new_metrics = res

  result_array.push(details = {
      :type => 'INFO',
      :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + new_metrics.uri,
      :api => server + new_metrics.uri,
      :title => '',
      :description => 'Results of the metric ('+ new_metrics.title + ') are in both projects equal.'
  })
  # count objects
  counter_ok += 1
end

#save errors in the result variable
$result.push({:section => 'Metric results between Start and Devel projects.', :OK => counter_ok, :ERROR => 0, :output => result_array})


#print out the result
puts $result.to_json

GoodData.disconnect
