require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# setup all parameters for user input
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-s', '--start_project ID', 'Start Project') { |v| options[:start_project] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_excluded] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
start_project = options[:start_project]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for standard output
counter_ok = 0
counter_error = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development and start GoodData projects
start_project = client.projects(start_project)
development_project = client.projects(development_project)

# select start project reports and include and exclude tags
start_project_reports = start_project.reports.select { |report| (tags_included.empty? || !(report.tag_set & tags_included).empty?) && (report.tag_set & tags_excluded).empty? }.sort_by(&:title)

# select development project reports and include and exclude tags
development_project_reports = development_project.reports.select { |report| (tags_included.empty? || !(report.tag_set & tags_included).empty?) && (report.tag_set & tags_excluded).empty? }.sort_by(&:title)

results = start_project_reports.zip(development_project_reports).pmap do |reports|
  # compute both reports and add the report at the end for being able to print a report later
  reports.map(&:execute) + [reports.last] #TODO ??
end

results.map do |result|
  orig_result, new_result, new_report = result

  if orig_result != new_result
    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + new_report.uri,
        :api => server + new_report.uri,
        :title => new_report.title,
        :message => 'Development report result is different.'
    })
    counter_error += 1
  else
    counter_ok += 1
  end
end

$result.push({:section => 'Compare report results', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect