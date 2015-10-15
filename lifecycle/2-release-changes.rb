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

# assign username and password to variables
username = options[:username]
password = options[:password]

# specify tags to ignore for releasing
ignore_tags = ['qa','poc']

# set the date from which we will be doing transfer
last_release_date = Time.parse(options[:date],'%e %b %Y')

# assign master project id to variable
master = options[:master]

# print some initial infor for the user
puts 'Connecting to GoodData...'
puts 'Objects updated after ' + last_release_date.to_s + ' will be updated.'

# get the CSV for all customers project
csv = CSV.read(options[:file], :headers => true)

# get all project ID from the CSV
target_projects = csv['project-id']
objects_to_migrate = Array.new

# connect to master project, select dashboards, reports and metrics to migrate, filter those without tags
GoodData.with_connection(username, password) do |client|
    GoodData.with_project(master) do |project|
        
      # get all dashboards
      dashboards_to_migrate = project.dashboards.select { |dashboard| dashboard.updated > last_release_date && !(ignore_tags.any? { |tag| dashboard.tags.include?(tag)})  }
      
      puts 'Exporting following dashboards from master...'
      
      # push all dashboard objects to the array that we will be migrating between projects
      dashboards_to_migrate.each do |dashboard|
      
            puts dashboard.title
            objects_to_migrate.push(dashboard)
            
      end
      
      puts 'Dashboards exported.'

      # get all reports
      reports_to_migrate = project.reports.select { |report| report.updated > last_release_date && !(ignore_tags.any? { |tag| report.tags.include?(tag)}) }

      puts 'Exporting following reports from master...'

      # push all reports objects to the array that we will be migrating between projects
      reports_to_migrate.each do |report|

        puts report.title
        objects_to_migrate.push(report)

      end
      
      puts 'Reports exported.'
      
      # get all metrics
      metrics_to_migrate = project.metrics.select { |metric| metric.updated > last_release_date && !(ignore_tags.any? { |tag| metric.tags.include?(tag)})  }

	  puts 'Exporting following metrics from master...'

      # push all metrics objects to the array that we will be migrating between projects
      metrics_to_migrate.each do |metric|
        puts metric.title
        objects_to_migrate.push(metric)
        
      end
      
      puts 'Metrics exported.'
      puts 'Importing objects to destination...'
      
      # migrate all objects between projects
      target_projects.each do |target|
          project.partial_md_export(objects_to_migrate, :project => target)
          puts 'Project ' + target + 'has been updated.'
      end

    end
end

puts 'All objects has been released'
puts 'Disconnecting...'
GoodData.disconnect
