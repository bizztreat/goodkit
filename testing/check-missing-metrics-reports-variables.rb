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
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }

end.parse!

# get parameters from the user input
username = options[:username]
password = options[:password]
start = options[:start]
devel = options[:devel]
server = options[:server]
incl = options[:incl]
excl = options[:excl]

# make arrays from incl and excl parameters
if incl.to_s != ''
  incl = incl.split(',')
end

if excl.to_s != ''
  excl = excl.split(',')
end

# counters and arrays for results
err_array_1 = []
err_array_2 = []
err_array_3 = []
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
  start_variables = []
  devel_variables = []

  # get all reports, metrics, variables from devel project
  GoodData.with_project(devel) do |project|

    project.reports.each do |report|
      if incl.to_s == '' || !(report.tag_set & incl).empty? then
        if excl.to_s == '' || (report.tag_set & excl).empty? then
          devel_reports.push(report.uri.gsub(devel, 'pid'))
        end
      end
    end

    project.metrics.each do |metric|
      if incl.to_s == '' || !(metric.tag_set & incl).empty? then
        if excl.to_s == '' || (metric.tag_set & excl).empty? then
          devel_metrics.push(metric.uri.gsub(devel, 'pid'))
        end
      end
    end

    project.variables.each do |variable|
      if incl.to_s == '' || !(variable.tag_set & incl).empty? then
        if excl.to_s == '' || (variable.tag_set & excl).empty? then
          devel_variables.push(variable.uri.gsub(devel, 'pid'))
        end
      end
    end
  end

  # get all reports and metrics from start project
  GoodData.with_project(start) do |project|

    project.reports.each do |report|
      if incl.to_s == '' || !(report.tag_set & incl).empty? then
        if excl.to_s == '' || (report.tag_set & excl).empty? then
          start_reports.push(report.uri.gsub(start, 'pid'))
        end
      end
    end

    project.metrics.each do |metric|
      if incl.to_s == '' || !(metric.tag_set & incl).empty? then
        if excl.to_s == '' || (metric.tag_set & excl).empty? then
          start_metrics.push(metric.uri.gsub(start, 'pid'))
        end
      end
    end

    project.variables.each do |variable|
      if incl.to_s == '' || !(variable.tag_set & incl).empty? then
        if excl.to_s == '' || (variable.tag_set & excl).empty? then
          start_variables.push(variable.uri.gsub(start, 'pid'))
        end
      end
    end
  end


  # diff for metrics
  metrics_diff = start_metrics - devel_metrics
  metrics_diff.each do |metric|
    err_array_1.push(error_details = {
        :type => 'ERROR',
        :url => server + '#s=/gdc/projects/' + start + '|objectPage|' + metric.gsub!('pid', start),
        :api => server + metric,
        :title => client.projects(start).metrics(metric.gsub('pid', start)).title,
        :description => 'Metric is missing in Devel project'
    })

  end

  # count errors and prepare details to the array
  counter_err = metrics_diff.count
  counter_ok = start_metrics.count - counter_err

  $result.push({:section => 'Metrics missing in Devel project', :OK => counter_ok, :ERROR => counter_err, :output => err_array_1})

  # diff for reports
  reports_diff = start_reports - devel_reports
  reports_diff.each do |report|

    err_array_2.push(error_details = {
        :type => 'ERROR',
        :url => server + '#s=/gdc/projects/' + start + '%7CanalysisPage%7Chead%7C' + report.gsub!('pid', start),
        :api => server + report,
        :title => client.projects(start).reports(report.gsub('pid', start)).title,
        :description => 'Report is missing in Devel project'
    })
  end

  # count errors and prepare details to the array
  counter_err = reports_diff.count
  counter_ok = start_reports.count - counter_err

  $result.push({:section => 'Reports missing in Devel project', :OK => counter_ok, :ERROR => counter_err, :output => err_array_2})

  # diff for variables
  variables_diff = start_variables - devel_variables
  variables_diff.each do |variable|

    err_array_3.push(error_details = {
        :type => 'ERROR',
        :url => server + '#s=/gdc/projects/' + start + '|objectPage|' + variable.gsub!('pid', start),
        :api => server + variable,
        :title => client.projects(start).variables(variable.gsub('pid', start)).title,
        :description => 'Variable is missing in Devel project'
    })
  end

  # count errors and prepare details to the array
  counter_err = variables_diff.count
  counter_ok = start_variables.count - counter_err

  $result.push({:section => 'Variables missing in Devel project', :OK => counter_ok, :ERROR => counter_err, :output => err_array_3})

  puts $result.to_json

end

GoodData.disconnect