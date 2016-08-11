require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-t', '--target_project ID', 'Target Project') { |v| options[:target_project] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tags excluded') { |v| options[:tags_excluded] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
target_project = options[:target_project]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for script results
counter_info = 0
output = []
$result = []
objects_to_migrate = Array.new

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# push all dashboard objects to the array that we will be migrating between projects
development_project.dashboards.each do |dashboard|

  if (dashboard.tag_set & tags_excluded).empty?
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
end

$result.push({:section => 'Following dashboards from development_project have been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})

# reset result variables
output = []
counter_info = 0

# push all reports objects to the array that we will be migrating between projects
development_project.reports.each do |report|

  if (report.tag_set & tags_excluded).empty?
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
end

$result.push({:section => 'Following reports from development_project have been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})

# reset result variables
output = []
counter_info = 0

# push all metrics objects to the array that we will be migrating between projects
development_project.metrics.each do |metric|

  if (metric.tag_set & tags_excluded).empty?
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
end

$result.push({:section => 'Following metrics from development_project have been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})

# reset result variables
output = []
counter_info = 0


# push all variables objects to the array that we will be migrating between projects
development_project.variables.each do |variable|

  if (variable.tag_set & tags_excluded).empty?
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
end

$result.push({:section => 'Following variable from development_project have been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})
puts $result.to_json

# TODO add analyticaldashboard in future, but it's not supported by GoodData now.

# migrate all objects between projects
unless objects_to_migrate.empty?
  development_project.partial_md_export(objects_to_migrate, :project => target_project)
end

client.disconnect
