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
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for standard output
counter_metrics_info = 0
counter_reports_info = 0
counter_dashboards_info = 0
output_1 = []
output_2 = []
output_3 = []
$result = []

# initiate two hashes to compare metrics and array for result
development_metrics = Hash.new
start_metrics = Hash.new
updated_metrics = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# get metric expression from development
project = client.projects(development_project)
project.metrics.each do |metric|
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?
      development_metrics.store(metric.uri.gsub(development_project, 'pid'), metric.expression.gsub(development_project, 'pid'))
    end
  end
end


# get metric expression from start project
project = client.projects(start_project)
project.metrics.each do |metric|
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?
      start_metrics.store(metric.uri.gsub(start_project, 'pid'), metric.expression.gsub(start_project, 'pid'))
    end
  end
end


project = client.projects(development_project)

# check all changes by updated metrics which have been changed
development_metrics.each_key do |uri|

  if start_metrics[uri] != development_metrics[uri]
    output_1.push(details = {
        :type => 'INFO',
        :url => server + '/#s=/gdc/projects/' + development_project + '|objectPage|' + uri.gsub('pid', development_project),
        :api => server + uri.gsub('pid', development_project),
        :title => project.metrics(uri.gsub('pid', development_project)).title,
        :description => 'This updated metric has been changed.'
    })
    updated_metrics.push(uri.gsub('pid', development_project))
    counter_metrics_info += 1
  end
end

$result.push({:section => 'Updated metrics which have been changed.', :OK => 0, :INFO => counter_metrics_info, :ERROR => 0, :output => output_1})

# all affected dashboards and reports for changed metric
updated_metrics.each do |uri|
  metric = project.metrics(uri)
  objects = metric.usedby

  objects.select { |object| object['category'] == 'report' }.each do |object|

    report = project.reports(object['link'])
    output_2.push(details = {
        :type => 'INFO',
        :url => server + '/#s=/gdc/projects/' + development_project + '%7CanalysisPage%7Chead%7C' + report.uri,
        :api => server + report.uri,
        :title => report.title,
        :description => 'Updated metric "' + metric.title + '" has been used in this report'
    })
    counter_reports_info += 1
  end

  objects.select { |object| object['category'] == 'projectDashboard' }.each do |object|

    dashboard = project.dashboards(object['link'])
    output_3.push(details = {
        :type => 'INFO',
        :url => server + '/#s=/gdc/projects/' + development_project + '|projectDashboardPage|' + dashboard.uri,
        :api => server + dashboard.uri,
        :title => dashboard.title,
        :description => 'Updated metric "' + metric.title + '" has been used in this dashboard'
    })
    counter_dashboards_info += 1
  end
end

# GROUP BY to count dashboard just once
output_3 = output_3.uniq

$result.push({:section => 'Reports in which have been used a changed metric', :OK => 0, :INFO => counter_reports_info, :ERROR => 0, :output => output_2})
$result.push({:section => 'Dashboard in which have been used a changed metric', :OK => 0, :INFO => counter_dashboards_info, :ERROR => 0, :output => output_3})
puts $result.to_json

client.disconnect