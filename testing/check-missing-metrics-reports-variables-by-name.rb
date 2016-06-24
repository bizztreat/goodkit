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
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_excluded] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
start_project = options[:start_project]
development_project = options[:development_project]
server = options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')


# variables for standard output
output_1 = []
output_2 = []
output_3 = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

start_project_reports = []
development_project_reports = []
start_project_metrics = []
development_project_metrics = []
start_project_variables = []
development_project_variables = []

# get all reports, metrics and variables from development project
project = client.projects(development_project)

project.reports.each do |report|
  if tags_included.empty? || !(report.tag_set & tags_included).empty?
    if (report.tag_set & tags_excluded).empty?
      development_project_reports.push({:uri => report.uri.gsub(development_project, 'pid'), :title => report.title})
    end
  end
end

project.metrics.each do |metric|
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?
      development_project_metrics.push({:uri => metric.uri.gsub(development_project, 'pid'), :title => metric.title})
    end
  end
end

project.variables.each do |variable|
  if tags_included.empty? || !(variable.tag_set & tags_included).empty?
    if (variable.tag_set & tags_excluded).empty?
      development_project_variables.push({:uri => variable.uri.gsub(development_project, 'pid'), :title => variable.title})
    end
  end
end


# get all reports, metrics and variables from start project
project = client.projects(start_project)

project.reports.each do |report|
  if tags_included.empty? || !(report.tag_set & tags_included).empty?
    if (report.tag_set & tags_excluded).empty?
      start_project_reports.push({:uri => report.uri.gsub(start_project, 'pid'), :title => report.title})
    end
  end
end

project.metrics.each do |metric|
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?
      start_project_metrics.push({:uri => metric.uri.gsub(start_project, 'pid'), :title => metric.title})
    end
  end
end

project.variables.each do |variable|
  if tags_included.empty? || !(variable.tag_set & tags_included).empty?
    if (variable.tag_set & tags_excluded).empty?
      start_project_variables.push({:uri => variable.uri.gsub(start_project, 'pid'), :title => variable.title})
    end
  end
end

client.disconnect

# diff for reports
reports_diff = start_project_reports - development_project_reports
reports_diff.each do |report|

  output_1.push(details = {
      :type => 'ERROR',
      :url => server + '#s=/gdc/projects/' + start_project + '%7CanalysisPage%7Chead%7C' + report[:uri].gsub!('pid', start_project),
      :api => server + report[:uri],
      :title => report[:title],
      :description => 'Report is missing in Devel project'
  })
end

# count errors
counter_error = reports_diff.count
counter_ok = start_project_reports.count - counter_error

$result.push({:section => 'Reports missing in Devel project', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output_1})

# diff for metrics
metrics_diff = start_project_metrics - development_project_metrics
metrics_diff.each do |metric|
  output_2.push(details = {
      :type => 'ERROR',
      :url => server + '#s=/gdc/projects/' + start_project + '|objectPage|' + metric[:uri].gsub!('pid', start_project),
      :api => server + metric[:uri],
      :title => metric[:title],
      :description => 'Metric is missing in Devel project'
  })

end

# count errors
counter_error = metrics_diff.count
counter_ok = start_project_metrics.count - counter_error

$result.push({:section => 'Metrics missing in Devel project', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output_2})

# diff for variables
variables_diff = start_project_variables - development_project_variables
variables_diff.each do |variable|

  output_3.push(details = {
      :type => 'ERROR',
      :url => server + '#s=/gdc/projects/' + start_project + '|objectPage|' + variable[:uri].gsub!('pid', start_project),
      :api => server + variable[:uri],
      :title => variable[:title],
      :description => 'Variable is missing in Devel project'
  })
end

# count errors
counter_error = variables_diff.count
counter_ok = start_project_variables.count - counter_error

$result.push({:section => 'Variables missing in Devel project', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output_3})
puts $result.to_json