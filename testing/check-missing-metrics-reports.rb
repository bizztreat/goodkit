require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# get all parameters
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get parameters from the user input
username = options[:username]
password = options[:password]
start = options[:start]
devel = options[:devel]
server = options[:server]

# counters and arrays for results
counter_ok = 0
counter_err = 0
err_array_1 = []
err_array_2 = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end

# connect to gooddata and check missing reports and metrics between projects
GoodData.with_connection(login: username, password: password, server: server) do |client|

  start_reports = []
  devel_reports = []
  start_metrics = []
  devel_metrics = []

  # get all reports and metrics from devel project
  GoodData.with_project(devel) do |project|

    project.reports.each do |report|
      devel_reports.push(report.uri.gsub(devel, "pid"))
    end

    project.metrics.each do |metric|
      devel_metrics.push(metric.uri.gsub(devel, "pid"))
    end
  end

  # get all reports and metrics from start project
  GoodData.with_project(start) do |project|

    project.reports.each do |report|
      start_reports.push(report.uri.gsub(start, "pid"))
    end

    project.metrics.each do |metric|
      start_metrics.push(metric.uri.gsub(start, "pid"))
    end
  end

  
  metrics_diff = start_metrics - devel_metrics

  if (metrics_diff.count > 0) then
    metrics_diff.each do |m|
      error_details = {
          :type => "ERROR",
          :url => server + '#s=/gdc/projects/' + start + '|objectPage|' + m.gsub!("pid", start),
          :api => server + m,
          :title => '', #TODO
          :description => "Metric is missing in Devel project"
      }

      # save detail to the array
      err_array_1.push(JSON.generate(error_details))
    end
  end

  # count errors and prepare details to the array
  counter_err = metrics_diff.count
  counter_ok = start_metrics.count - counter_err

  $result.push({:section => 'Metrics missing in Devel project', :OK => counter_ok, :ERROR => counter_err, :output => err_array_1})

  # print the diff for reports
  reports_diff = start_reports - devel_reports

  if (reports_diff.count > 0) then

    reports_diff.each do |r|

      error_details = {
          :type => "ERROR",
          :url => server + '#s=/gdc/projects/' + start + '%7CanalysisPage%7Chead%7C' + r.gsub!("pid", start),
          :api => server + r,
          :title => '', #TODO
          :description => "Report is missing in Devel project"
      }

      # save detail to the array
      err_array_2.push(JSON.generate(error_details))
    end
  end

  # count errors and prepare details to the array
  counter_err = reports_diff.count
  counter_ok = start_reports.count - counter_err

  $result.push({:section => 'Reports missing in Devel project', :OK => counter_ok, :ERROR => counter_err, :output => err_array_2})

  puts $result.to_json

end

GoodData.disconnect



