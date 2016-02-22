require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# get all options for user input
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-m', '--masterproject NAME', 'Master Project') { |v| options[:master] = v }
  opts.on('-d', '--releasedate DATE', 'Release Date') { |v| options[:date] = v }
  opts.on('-f', '--file FILE', 'Projects file') { |v| options[:file] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  # set tags to ingnore. Use this format only!:['tag1','tag2'] for example:['qa','test'] 
  opts.on('-t', '--tags TAGS', 'Tags') { |v| options[:tags] = v }

end.parse!

# assign credentials from user input
username = options[:username]
password = options[:password]
server = options[:server]
ignore_tags = options[:tags]

# variables for script results
result_array = []
$result = []
counter_ok = 0
counter_err = 0



# if not whitelabeled set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end
  
# turn off GoodData logging
GoodData.logging_off

# set date from which we will check unfinished objects
last_release_date = Time.parse(options[:date],'%e %b %Y')

# assign master project to variable
master = options[:master]


# connect to GoodData and check all objects for specific setup
GoodData.with_connection(login: username, password: password, server: server) do |client|
    
    GoodData.with_project(master) do |project|


     #-----------------------------DASHBOARDS------------------------------------
     dashboards_to_migrate = project.dashboards.select { |dashboard| dashboard.updated > last_release_date && !(ignore_tags.any? { |tag| dashboard.tags.include?(tag)})}
     
      # print all dashboards with unfinished setup
      dashboards_to_migrate.each do |dashboard|
   	    if !(dashboard.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
        if (dashboard.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
        if (dashboard.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
        if (unlocked != '' || missing_desc != '' || unlisted != '')
            then
            counter_err += 1
            result_array.push(error_details = {
                               :type => "ERROR",
                               :url => server + '#s=/gdc/projects/' + master + '|projectDashboardPage|' + dashboard.uri ,
                               :api => server + dashboard.uri ,
                               :message => 'The dashboard ('+ dashboard.title + ') - errors: ' + unlocked + missing_desc + unlisted
                               })
            else
            counter_ok += 1
          end
	  end
	  #save errors in the result variable
    $result.push({:section => 'Unfinished dashboards.', :OK => counter_ok, :ERROR => counter_err , :output => result_array})
    #reset result variables
    result_array = []
    counter_ok = 0
    counter_err = 0
    
    #-----------------------------REPORTS-----------------------------------
      reports_to_migrate = project.reports.select { |report| report.updated > last_release_date && !(ignore_tags.any? { |tag| report.tags.include?(tag)}) }
            
      # print all reports with unfinished setup
      reports_to_migrate.each do |report|
          if !(report.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
          if (report.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
          if (report.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
          if (unlocked != '' || missing_desc != '' || unlisted != '')
              then
            counter_err += 1
            result_array.push(error_details = {
                               :type => "ERROR",
                               :url => server + '#s=/gdc/projects/' + master + '|analysisPage|head|' + report.uri ,
                               :api => server + report.uri ,
                               :message => 'The report ('+ report.title + ') - errors: ' + unlocked + missing_desc + unlisted
                               })
            else
            counter_ok += 1
              
              end
          end
    #save errors in the result variable
    $result.push({:section => 'Unfinished reports.', :OK => counter_ok, :ERROR => counter_err , :output => result_array})
    #reset result variables
    result_array = []
    counter_ok = 0
    counter_err = 0
    
    #-----------------------------METRICS-----------------------------------
      metrics_to_migrate = project.metrics.select { |metric| metric.updated > last_release_date && !(ignore_tags.any? { |tag| metric.tags.include?(tag)})  }

      # print all metrics with unfinished setup
      metrics_to_migrate.each do |metric|
   	    if !(metric.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
        if (metric.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
        if (metric.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
        if (unlocked != '' || missing_desc != '' || unlisted != '')
             then
            counter_err += 1
            result_array.push(error_details = {
                               :type => "ERROR",
                               :url => server + '#s=/gdc/projects/' + master + '|objectPage|' + metric.uri ,
                               :api => server + metric.uri ,
                               :message => 'The metric ('+ metric.title + ') - errors: ' + unlocked + missing_desc + unlisted
                               })
            else
            counter_ok += 1
         end
    end
 #save errors in the result variable
    $result.push({:section => 'Unfinished metrics.', :OK => counter_ok, :ERROR => counter_err , :output => result_array})

    
    end
end
#print out the result
puts $result.to_json

GoodData.disconnect