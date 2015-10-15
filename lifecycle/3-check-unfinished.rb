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
  
end.parse!

# assign credentials from user input
username = options[:username]
password = options[:password]

# set ignore tags
ignore_tags = ['qa','poc']

# set date from which we will check unfinished objects
last_release_date = Time.parse(options[:date],'%e %b %Y')

# assign master project to variable
master = options[:master]

puts 'Connecting to GoodData...'
puts 'Listing objects updated after ' + last_release_date.to_s + '.'

# connect to GoodData and check all objects for specific setup
GoodData.with_connection(username, password) do |client|
    
    GoodData.with_project(master) do |project|

     dashboards_to_migrate = project.dashboards.select { |dashboard| dashboard.updated > last_release_date && !(ignore_tags.any? { |tag| dashboard.tags.include?(tag)})}

     puts 'Check unfinished dashboards...'

      # print all dashboards with unfinished setup
      dashboards_to_migrate.each do |dashboard|
   	    if !(dashboard.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
        if (dashboard.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
        if (dashboard.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
        if (unlocked != '' || missing_desc != '' || unlisted != '')
            then
        puts 'https://secure.gooddata.com#s=/gdc/projects/' + master + '|projectDashboardPage|' + dashboard.uri + ' | ' + dashboard.title + unlocked + missing_desc + unlisted
            end
	  end
      
      reports_to_migrate = project.reports.select { |report| report.updated > last_release_date && !(ignore_tags.any? { |tag| report.tags.include?(tag)}) }
      
      puts 'Check unfinished reports...'
      
      # print all reports with unfinished setup
      reports_to_migrate.each do |report|
          if !(report.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
          if (report.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
          if (report.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
          if (unlocked != '' || missing_desc != '' || unlisted != '')
              then
          puts 'https://secure.gooddata.com#s=/gdc/projects/' + master + '|analysisPage|head|' + report.uri + ' | ' + report.title + unlocked + missing_desc + unlisted
              end
          end
    
    
      metrics_to_migrate = project.metrics.select { |metric| metric.updated > last_release_date && !(ignore_tags.any? { |tag| metric.tags.include?(tag)})  }

	  puts 'Check unfinished metrics...'

      # print all metrics with unfinished setup
      metrics_to_migrate.each do |metric|
   	    if !(metric.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
        if (metric.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
        if (metric.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
        if (unlocked != '' || missing_desc != '' || unlisted != '')
            then
        puts 'https://secure.gooddata.com#s=/gdc/projects/' + master + '|objectPage|' + metric.uri + ' | ' + metric.title + unlocked + missing_desc + unlisted
            end
    end

    end
end

puts 'Disconnecting ...'
GoodData.disconnect