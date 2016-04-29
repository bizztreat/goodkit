# Check metrics definition changes
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and project ids
username = options[:username]
password = options[:password]
start = options[:start]
devel = options[:devel]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end

counter_ok = 0
counter_err = 0
count_reports = 0
count_dashboards = 0
err_array_1 = []
err_array_2 = []
err_array_3 = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|

  # initiate two hashes to compare metrics and array for result
  $devel_metrics = Hash.new
  $start_metrics = Hash.new
  $updated_metrics = []

  # connect to devel project and get metric expression
  GoodData.with_project(devel) do |project|

    #prepare count reports and dasboards for output
    count_reports = project.reports.count
    count_dashboards = project.dashboards.count

    #get metric expression from devel project
    project.metrics.each do |metric|
      $devel_metrics.store(metric.uri.gsub(devel, "pid"), metric.expression.gsub(devel, "pid"))
      #puts $devel_metrics.keys
    end

  end

  # connect to start project and get metric expression
  GoodData.with_project(start) do |project|

    project.metrics.each do |metric|
      $start_metrics.store(metric.uri.gsub(start, "pid"), metric.expression.gsub(start, "pid"))
      # puts $start_metrics.keys
    end
  end


  # print updated metrics that have been changed
  $devel_metrics.each_key { |key|

    if $start_metrics[key] != $devel_metrics[key] then
      #metric = project.metrics(key)
      counter_err += 1
      err_array_1.push(error_details = {
          :type => "ERROR",
          :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + key.gsub("pid", devel),
          :api => server + key.gsub("pid", devel),
          :title => '', #TODO
          :description => "This updated metric has been changed."
      })
      $updated_metrics.push(key.gsub("pid", devel))
    else
      counter_ok += 1
    end
  }
  $result.push({:section => 'Updated metrics which have been changed.', :OK => counter_ok, :ERROR => counter_err, :output => err_array_1})
  counter_err = 0
  project = client.projects(devel)

  # print all affected dashboards and reports for changed metric
  $updated_metrics.each do |met|
    metric = project.metrics(met)
    objects = metric.usedby
    objects.select { |report| report["category"] == 'report' }.each { |r|
      # get only report objects and extract tags
      obj = GoodData::get(r["link"])
      err_array_2.push(error_details = {
          :type => "ERROR",
          :url => server + "/#s=/gdc/projects/" + devel + "%7CanalysisPage%7Chead%7C" + obj['report']['meta']['uri'],
          :api => server + obj['report']['meta']['uri'],
          :title => metric.title,
          :description => 'Updated metric: ' + metric.title + ' has been used in this report: '+ obj['report']['meta']['title']
      })
      counter_err += 1

      # Dashboards
      objects.select { |dashboard| dashboard["category"] == 'projectDashboard' }.each { |r|
        # get only report objects and extract tags
        obj = GoodData::get(r["link"])

        err_array_3.push(error_details = {
            :type => "ERROR",
            :url => server + "/#s=/gdc/projects/" + devel + "|projectDashboardPage|" + obj['projectDashboard']['meta']['uri'],
            :api => server + obj['projectDashboard']['meta']['uri'],
            :title => metric.title,
            :description => 'Updated metric: ' + metric.title + ' has been used in this dashboard: '+ obj['projectDashboard']['meta']['title']
        })

      }
    }

  end
  # group_by to count dashboard just once
  err_array_3 = err_array_3.uniq
  # number of dashboards where have been used a changed metrics
  counter_err3 = err_array_3.count
  # save error lists to array and prepare for a json creation
  $result.push({:section => 'Reports in which have been used a changed metric', :OK => count_reports - counter_err, :ERROR => counter_err, :output => err_array_2})
  $result.push({:section => 'Dashboard in which have been used a changed metric', :OK => count_dashboards - counter_err3, :ERROR => counter_err3, :output => err_array_3})

  # result as json_file
  puts $result.to_json

end
GoodData.disconnect
