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
server = options[:server]
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for script results
output = []
$result = []
counter_info = 0

# if not specific white labeled server set to default
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# turn off GoodData logging
GoodData.logging_off

# set the date from we will check changes
last_release_date = Time.strptime(options[:release_date], '%Y-%m-%d')

# read all project ids there we will check changes
csv = CSV.read(options[:file], :headers => true)
target_projects = csv['project-id']

objects_to_migrate = Array.new

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|

  # connect to development GoodData project
  GoodData.with_project(development_project) do |project|

    # get all dashboards
    dashboards_to_migrate = project.dashboards.select { |dashboard| dashboard.updated > last_release_date && (dashboard.tag_set & tags_excluded).empty? }

    # push all dashboard objects to the array that we will be migrating between projects
    dashboards_to_migrate.each do |dashboard|

      objects_to_migrate.push(dashboard)
      counter_info += 1
      output.push(error_details = {
          :type => 'INFO',
          :url => server + '#s=/gdc/projects/' + development_project + '|projectDashboardPage|' + dashboard.uri,
          :api => server + dashboard.uri,
          :message => 'The dashboard '+ dashboard.title + ' has been exported'
      })
    end

    $result.push({:section => 'Following dashboards from development_project updated after ' + last_release_date.to_s + ' has been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})

    # reset result variables
    output = []
    counter_info = 0

    # get all reports
    reports_to_migrate = project.reports.select { |report| report.updated > last_release_date && (report.tag_set & tags_excluded).empty? }

    # push all reports objects to the array that we will be migrating between projects
    reports_to_migrate.each do |report|
      objects_to_migrate.push(report)
      counter_info += 1
      output.push(error_details = {
          :type => 'INFO',
          :url => server + '#s=/gdc/projects/' + development_project + '|analysisPage|head|' + report.uri,
          :api => server + report.uri,
          :message => 'The report '+ report.title + ' has been exported.'
      })
    end

    $result.push({:section => 'Following reports from development_project updated after ' + last_release_date.to_s + ' has been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})

    # reset result variables
    output = []
    counter_info = 0

    # get all metrics
    metrics_to_migrate = project.metrics.select { |metric| metric.updated > last_release_date && (metric.tag_set & tags_excluded).empty? }

    # push all metrics objects to the array that we will be migrating between projects
    metrics_to_migrate.each do |metric|
      objects_to_migrate.push(metric)
      counter_info += 1
      output.push(error_details = {
          :type => 'INFO',
          :url => server + '#s=/gdc/projects/' + development_project + '|objectPage|' + metric.uri,
          :api => server + metric.uri,
          :message => 'The metric '+ metric.title + ' has been exported.'
      })
    end

    $result.push({:section => 'Following metrics from development_project updated after ' + last_release_date.to_s + ' has been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})

    # reset result variables
    output = []
    counter_info = 0

    # get all variables
    variables_to_migrate = project.variables.select { |variable| variable.updated > last_release_date && (variable.tag_set & tags_excluded).empty? }

    # push all variables objects to the array that we will be migrating between projects
    variables_to_migrate.each do |variable|
      objects_to_migrate.push(variable)
      counter_info += 1
      output.push(error_details = {
          :type => 'INFO',
          :url => server + '#s=/gdc/projects/' + development_project + '|objectPage|' + variable.uri,
          :api => server + variable.uri,
          :message => 'The variable '+ variable.title + ' has been exported.'
      })
    end

    $result.push({:section => 'Following variable from development_project updated after ' + last_release_date.to_s + ' has been exported.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})
    puts $result.to_json

    # migrate all objects between projects
    unless objects_to_migrate.empty?
      target_projects.each do |target_project|
        project.partial_md_export(objects_to_migrate, :project => target_project)
      end
    end
  end
end

GoodData.disconnect
