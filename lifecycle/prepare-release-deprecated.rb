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
  opts.on('-m', '--masterproject NAME', 'Master Project') { |v| options[:master] = v }
  opts.on('-d', '--releasedate DATE', 'Release Date') { |v| options[:date] = v }
  opts.on('-f', '--file FILE', 'Projects file') { |v| options[:file] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-t', '--tags TAGS', 'Tags') { |v| options[:tags] = v } # change the tags to ignore here. Use this format only!:['tag1','tag2'] for example:['qa','test']


end.parse!

#collecting username and password from parameters
username = options[:username]
password = options[:password]
server = options[:server]
ignore_tags = tags[:server]

# variables for script results
result_array = []
$result = []
counter_err = 0

# if whitelabel is not specified set to default domain
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end

# turn off GoodData logging
GoodData.logging_off

# set last released date we want to check
last_release_date = Time.strptime(options[:date], '%Y-%m-%d')


# get master project id from parameters
master = options[:master]

# create GoodData connection
GoodData.with_connection(login: username, password: password, server: server) do |client|

  # connect to specific GoodData project
  GoodData.with_project(master) do |project|

    #-----------------------------DASHBOARDS------------------------------------
    # get all dashboards changed from specific date and not including specified tags
    dashboards_to_migrate = project.dashboards.select { |dashboard| dashboard.updated > last_release_date && !(ignore_tags.any? { |tag| dashboard.tags.include?(tag) }) }

    # check dashboard setup and save to result array
    dashboards_to_migrate.each do |dashboard|
      if !(dashboard.locked?) then
        unlocked = ' | UNLOCKED!'
      else
        unlocked = ''
      end
      if (dashboard.summary == '') then
        missing_desc = ' | MISSING DESCRIPTION'
      else
        missing_desc = ''
      end
      if (dashboard.meta['unlisted'] == 1) then
        unlisted = ' | UNLISTED!'
      else
        unlisted = ''
      end

      counter_err += 1
      result_array.push(error_details = {
          :type => "INFO",
          :url => server + '#s=/gdc/projects/' + master + '|projectDashboardPage|' + dashboard.uri,
          :api => server + dashboard.uri,
          :message => 'The dashboard ('+ dashboard.title + ') - errors: ' + unlocked + missing_desc + unlisted
      })

    end
    #save errors in the result variable
    $result.push({:section => 'Dashboards updated after ' + last_release_date.to_s + '.', :OK => project.dashboards.count - counter_err, :ERROR => counter_err, :output => result_array})
    #reset result variables
    result_array = []
    counter_err = 0

    #-----------------------------REPORTS-----------------------------------
    # get all reports changed from specific date and not including specified tags
    reports_to_migrate = project.reports.select { |report| report.updated > last_release_date && !(ignore_tags.any? { |tag| report.tags.include?(tag) }) }

    # check reports setup and save to result array
    reports_to_migrate.each do |report|
      unless report.locked?
        unlocked = ' | UNLOCKED!'
      else
        unlocked = ''
      end

      if (report.summary == '') then
        missing_desc = ' | MISSING DESCRIPTION'
      else
        missing_desc = ''
      end

      if (report.meta['unlisted'] == 1) then
        unlisted = ' | UNLISTED!'
      else
        unlisted = ''
      end

      counter_err += 1
      result_array.push(error_details = {
          :type => "INFO",
          :url => server + '#s=/gdc/projects/' + master + '|analysisPage|head|' + report.uri,
          :api => server + report.uri,
          :message => 'The report ('+ report.title + ') - errors: ' + unlocked + missing_desc + unlisted
      })
    end
    #save errors in the result variable
    $result.push({:section => 'Reports updated after ' + last_release_date.to_s + '.', :OK => project.reports.count - counter_err, :ERROR => counter_err, :output => result_array})
    #reset result variables
    result_array = []
    counter_err = 0

    #-----------------------------METRICS-----------------------------------
    # get all metrics changed from specific date and not including specified tags
    metrics_to_migrate = project.metrics.select { |metric| metric.updated > last_release_date && !(ignore_tags.any? { |tag| metric.tags.include?(tag) }) }

    # check metric setup and save to result array
    metrics_to_migrate.each do |metric|
      if metric.locked?
        unlocked = ''
      else
        unlocked = ' | UNLOCKED!'
      end

      if metric.summary == ''
        missing_desc = ' | MISSING DESCRIPTION'
      else
        missing_desc = ''
      end

      if metric.meta['unlisted'] == 1
        unlisted = ' | UNLISTED!'
      else
        unlisted = ''
      end

      counter_err += 1
      result_array.push(error_details = {
          :type => "ERROR",
          :url => server + '#s=/gdc/projects/' + master + '|objectPage|' + metric.uri,
          :api => server + metric.uri,
          :message => 'The metric ('+ metric.title + ') - errors: ' + unlocked + missing_desc + unlisted
      })
    end

    #save errors in the result variable
    $result.push({:section => 'Metrics updated after ' + last_release_date.to_s + '.', :OK => project.metrics.count - counter_err, :ERROR => counter_err, :output => result_array})

  end
end
#print out the result
puts $result.to_json

GoodData.disconnect