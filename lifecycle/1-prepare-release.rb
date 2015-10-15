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
  
end.parse!

#collecting username and password from parameters
username = options[:username]
password = options[:password]

# set other parameters like tags to ignore
ignore_tags = ['qa','poc']

# set last released date we want to check
last_release_date = Time.parse(options[:date],'%e %b %Y')

# get master project id from parameters
master = options[:master]

puts 'Connecting to GoodData...'
puts 'Listing objects updated after ' + last_release_date.to_s + '.'

# create GoodData connection
GoodData.with_connection(username, password) do |client|
    
    # connect to specific GoodData project
    GoodData.with_project(master) do |project|
        
    # get all dashboards changed from specific date and not including specified tags
    dashboards_to_migrate = project.dashboards.select { |dashboard| dashboard.updated > last_release_date && !(ignore_tags.any? { |tag| dashboard.tags.include?(tag)})  }

    puts 'Check dashboards to be released...'

      # check dashboard setup and print the output with all notes
      dashboards_to_migrate.each do |dashboard|
   	    if !(dashboard.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
        if (dashboard.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
        if (dashboard.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
        
        # print clickable ling to the dashboard
        puts 'https://secure.gooddata.com#s=/gdc/projects/' + master + '|projectDashboardPage|' + dashboard.uri + ' | ' + dashboard.title + unlocked + missing_desc + unlisted
        
	  end
      
      # get all reports changed from specific date and not including specified tags
      reports_to_migrate = project.reports.select { |report| report.updated > last_release_date && !(ignore_tags.any? { |tag| report.tags.include?(tag)}) }
      
      puts 'Check reports to be released...'
      
      # check reports setup and print the output with all notes
      reports_to_migrate.each do |report|
          if !(report.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
          if (report.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
          if (report.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
          puts 'https://secure.gooddata.com#s=/gdc/projects/' + master + '|analysisPage|head|' + report.uri + ' | ' + report.title + unlocked + missing_desc + unlisted
      end
    
      # get all metrics changed from specific date and not including specified tags
      metrics_to_migrate = project.metrics.select { |metric| metric.updated > last_release_date && !(ignore_tags.any? { |tag| metric.tags.include?(tag)})  }

	  puts 'Check metrics to be released...'

      # check metric setup and print the output with all notes
      metrics_to_migrate.each do |metric|
   	    if !(metric.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
        if (metric.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
        if (metric.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
        puts 'https://secure.gooddata.com#s=/gdc/projects/' + master + '|objectPage|' + metric.uri + ' | ' + metric.title + unlocked + missing_desc + unlisted
	  end

    end
end

# disconnect from GoodData
puts 'Disconnecting ...'
GoodData.disconnect