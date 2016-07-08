require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'json'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_excluded] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for script results
counter_ok = 0
counter_error = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# check all reports for missing tags
development_project.reports.each do |report|
  if tags_included.empty? || !(report.tag_set & tags_included).empty?
    if (report.tag_set & tags_excluded).empty?

      if report.tags =~ /\d+(\.\d+)?/
        counter_ok += 1
      else
        output.push(details = {
            :type => 'ERROR',
            :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + report.uri,
            :api => server + report.uri,
            :title => report.title,
            :description => 'Report does not have a version tag.'
        })
        counter_error += 1
      end
    end
  end
end

$result.push({:section => 'Reports without version tags', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})

# reset output variables
counter_ok = 0
counter_error = 0
output = []

# check all metrics for missing tags
development_project.metrics.each do |metric|
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?

      if metric.tags =~ /\d+(\.\d+)?/
        counter_ok += 1
      else
        output.push(details = {
            :type => 'ERROR',
            :url => server + '#s=' + development_project.uri + '|objectPage|' + metric.uri,
            :api => server + metric.uri,
            :title => metric.title,
            :description => 'Metric does not have a version tag.'
        })
        counter_error += 1
      end
    end
  end
end

$result.push({:section => 'Metrics without version tags', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})

# reset output variables
counter_ok = 0
counter_error = 0
output = []

# check all variables for missing tags
development_project.variables.each do |variable|
  if tags_included.empty? || !(variable.tag_set & tags_included).empty?
    if (variable.tag_set & tags_excluded).empty?

      if variable.tags =~ /\d+(\.\d+)?/
        counter_ok += 1
      else
        output.push(details = {
            :type => 'ERROR',
            :url => server + '#s=' + development_project.uri + '|objectPage|' + variable.uri,
            :api => server + variable.uri,
            :title => variable.title,
            :description => 'Variable does not have a version tag.'
        })
        counter_error += 1
      end
    end
  end
end

$result.push({:section => 'Variables without version tags', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})

# TODO add analyticaldashboard in future, but it's not supported by GoodData now.

puts $result.to_json

client.disconnect
