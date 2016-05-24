require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# setting up available options / parameters for the script
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-m', '--masterproject NAME', 'Master Project') { |v| options[:master] = v }
  opts.on('-d', '--releasedate DATE', 'Release Date') { |v| options[:date] = v }
  opts.on('-f', '--file FILE', 'Projects file') { |v| options[:file] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  # change the tags to ignore here. Use this format only!:['tag1','tag2'] for example:['qa','test'] 
  opts.on('-t', '--tags TAGS', 'Tags') { |v| options[:tags] = v }

end.parse!

# assign username and password to variables
username = options[:username]
password = options[:password]
server = options[:server]
ignore_tags = options[:tags].split(",") #TODO


# variables for script results
result_array = []
$result = []
counter = 0

# if not specific white labeled server set to default
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# turn off GoodData logging
GoodData.logging_off

# set the date from which we will be doing transfer
#last_release_date = Time.parse(options[:date], '%e %b %Y')
last_release_date = (Time.now - 3600*24)

# assign master project id to variable
master = options[:master]

# get the CSV for all customers project
csv = CSV.read(options[:file], :headers => true)

# get all project ID from the CSV
target_projects = csv['project-id']
objects_to_migrate = Array.new

# connect to master project, select dashboards, reports and metrics to migrate, filter those without tags
GoodData.with_connection(login: username, password: password, server: server) do |client|
  GoodData.with_project(master) do |project|

    # -----------------------DASHBOARDS---------------------------------
    # get all dashboards
    dashboards_to_migrate = project.dashboards.select { |dashboard| dashboard.updated > last_release_date && !(ignore_tags.any? { |tag| dashboard.tags.include?(tag) }) }

    # push all dashboard objects to the array that we will be migrating between projects
    dashboards_to_migrate.each do |dashboard|

      objects_to_migrate.push(dashboard)
      counter += 1
      result_array.push(error_details = {
          :type => "INFO",
          :url => server + '#s=/gdc/projects/' + master + '|projectDashboardPage|' + dashboard.uri,
          :api => server + dashboard.uri,
          :message => 'The dashboard '+ dashboard.title + ' has been exported'
      })

    end
    #save errors in the result variable
    $result.push({:section => 'Following dashboards from master updated after ' + last_release_date.to_s + ' has been exported.', :OK => counter, :ERROR => 0, :output => result_array})
    #reset result variables
    result_array = []
    counter = 0


    # -----------------------REPORTS---------------------------------
    # get all reports
    reports_to_migrate = project.reports.select { |report| report.updated > last_release_date && !(ignore_tags.any? { |tag| report.tags.include?(tag) }) }

    # push all reports objects to the array that we will be migrating between projects
    reports_to_migrate.each do |report|
      objects_to_migrate.push(report)
      counter += 1
      result_array.push(error_details = {
          :type => "INFO",
          :url => server + '#s=/gdc/projects/' + master + '|analysisPage|head|' + report.uri,
          :api => server + report.uri,
          :message => 'The report '+ report.title + ' has been exported.'
      })
    end
    #save errors in the result variable
    $result.push({:section => 'Following reports from master updated after ' + last_release_date.to_s + ' has been exported.', :OK => counter, :ERROR => 0, :output => result_array})
    #reset result variables
    result_array = []
    counter = 0

    # -----------------------METRICS----------------------------------
    # get all metrics
    metrics_to_migrate = project.metrics.select { |metric| metric.updated > last_release_date && !(ignore_tags.any? { |tag| metric.tags.include?(tag) }) }

    # push all metrics objects to the array that we will be migrating between projects
    metrics_to_migrate.each do |metric|
      objects_to_migrate.push(metric)
      counter += 1
      result_array.push(error_details = {
          :type => "INFO",
          :url => server + '#s=/gdc/projects/' + master + '|objectPage|' + metric.uri,
          :api => server + metric.uri,
          :message => 'The metric '+ metric.title + ' has been exported.'
      })
    end

    #save errors in the result variable
    $result.push({:section => 'Following metrics from master updated after ' + last_release_date.to_s + ' has been exported.', :OK => counter, :ERROR => 0, :output => result_array})


    # migrate all objects between projects
    if !objects_to_migrate.empty?
      target_projects.each do |target|
        project.partial_md_export(objects_to_migrate, :project => target)
      end
    end

  end
end
#print out the result
puts $result.to_json

GoodData.disconnect
