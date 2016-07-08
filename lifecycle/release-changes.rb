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
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-r', '--release_date DATE', 'Release Date') { |v| options[:release_date] = v }
  opts.on('-f', '--file FILE', 'Projects file') { |v| options[:file] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tags excluded') { |v| options[:tags_excluded] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for script results
output = []
$result = []
counter_info = 0

# turn off GoodData logging
GoodData.logging_off

# set the date from we will check changes
last_release_date = Time.strptime(options[:release_date], '%Y-%m-%d')

# read all project ids there we will check changes
csv = CSV.read(options[:file], :headers => true)
target_projects = csv['project-id']

objects_to_migrate = Array.new

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# get all dashboards
dashboards_to_migrate = development_project.dashboards.select { |dashboard| dashboard.updated > last_release_date && (dashboard.tag_set & tags_excluded).empty? }

# push all dashboard objects to the array that we will be migrating between projects
dashboards_to_migrate.each do |dashboard|

  objects_to_migrate.push(dashboard)
  output.push(details = {
      :type => 'INFO',
      :url => server + '#s=' + development_project.pid + '|projectDashboardPage|' + dashboard.uri,
      :api => server + dashboard.uri,
      :title => dashboard.title,
      :description => 'The dashboard has been exported'
  })
  counter_info += 1
end

$result.push({:section => 'Following dashboards from development_project updated after ' + last_release_date.to_s + ' has been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})

# reset result variables
output = []
counter_info = 0

# get all reports
reports_to_migrate = development_project.reports.select { |report| report.updated > last_release_date && (report.tag_set & tags_excluded).empty? }

# push all reports objects to the array that we will be migrating between projects
reports_to_migrate.each do |report|

  objects_to_migrate.push(report)
  output.push(details = {
      :type => 'INFO',
      :url => server + '#s=' + development_project.pid + '|analysisPage|head|' + report.uri,
      :api => server + report.uri,
      :title => report.title,
      :description => 'The report has been exported.'
  })
  counter_info += 1
end

$result.push({:section => 'Following reports from development_project updated after ' + last_release_date.to_s + ' has been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})

# reset result variables
output = []
counter_info = 0

# get all metrics
metrics_to_migrate = development_project.metrics.select { |metric| metric.updated > last_release_date && (metric.tag_set & tags_excluded).empty? }

# push all metrics objects to the array that we will be migrating between projects
metrics_to_migrate.each do |metric|

  objects_to_migrate.push(metric)
  output.push(details = {
      :type => 'INFO',
      :url => server + '#s=' + development_project.pid + '|objectPage|' + metric.uri,
      :api => server + metric.uri,
      :title => metric.title,
      :description => 'The metric has been exported.'
  })
  counter_info += 1
end

$result.push({:section => 'Following metrics from development_project updated after ' + last_release_date.to_s + ' has been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})

# reset result variables
output = []
counter_info = 0

# get all variables
variables_to_migrate = development_project.variables.select { |variable| variable.updated > last_release_date && (variable.tag_set & tags_excluded).empty? }

# push all variables objects to the array that we will be migrating between projects
variables_to_migrate.each do |variable|

  objects_to_migrate.push(variable)
  output.push(details = {
      :type => 'INFO',
      :url => server + '#s=' + development_project.pid + '|objectPage|' + variable.uri,
      :api => server + variable.uri,
      :title => variable.title,
      :description => 'The variable has been exported.'
  })
  counter_info += 1
end

$result.push({:section => 'Following variable from development_project updated after ' + last_release_date.to_s + ' has been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})
puts $result.to_json

# TODO add analyticaldashboard in future, but it's not supported by GoodData now.

# migrate all objects between projects
unless objects_to_migrate.empty?
  target_projects.each do |target_project|
    development_project.partial_md_export(objects_to_migrate, :project => target_project)
  end
end

client.disconnect
