require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-m', '--masterproject NAME', 'Master Project') { |v| options[:master] = v }
  opts.on('-d', '--releasedate DATE', 'Release Date') { |v| options[:date] = v }
  opts.on('-f', '--file FILE', 'Projects file') { |v| options[:file] = v }
  
end.parse!

#username = ''
#password = ''
username = options[:username]
password = options[:password]

ignore_tags = ['qa','poc']
last_release_date = Date.parse(options[:date],'%e %b %Y')
master = options[:master]
# testing master project ID = y672cuxov5x6swn64tlaz5jwcrez0wid

puts 'Connecting to GoodData...'
puts 'Objects updated after ' + last_release_date.to_s + ' will be updated.'

csv = CSV.read(options[:file], :headers => true)
target_projects = csv['project-id']

GoodData.with_connection(username, password) do |client|
    GoodData.with_project(master) do |project|

      reports_to_migrate = project.reports.select { |report| report.updated > last_release_date && !(ignore_tags.any? { |tag| report.tags.include?(tag)}) }


        puts 'Exporting following reports from master...'

      reports_to_migrate.each do |report|

        puts report.title
        
       		target_projects.each do |target|
	    		project.partial_md_export(report, :project => target)
	    		puts 'Project ' + target + 'has been updated with report ' + report.title
			end
      end
      
	  dashboards_to_migrate = project.dashboards.select { |dashboard| dashboard.updated > last_release_date && !(ignore_tags.any? { |tag| dashboard.tags.include?(tag)})  }
      puts 'Exporting following dashboards from master...'

      dashboards_to_migrate.each do |dashboard|
        puts dashboard.title 
	    
		    target_projects.each do |target|
	    		project.partial_md_export(dashboard, :project => target)
	    		puts 'Project ' + target + 'has been updated with dashboard ' + dashboard.title

			end
	    
      end
      
      metrics_to_migrate = project.metrics.select { |metric| metric.updated > last_release_date && !(ignore_tags.any? { |tag| metric.tags.include?(tag)})  }

	  puts 'Exporting following metrics from master...'

      metrics_to_migrate.each do |metric|
        puts metric.title
        
        	 target_projects.each do |target|
	    		project.partial_md_export(metric, :project => target)
	    		puts 'Project ' + target + 'has been updated with metric ' + metric.title
			end
	  end


    end
end

puts 'All objects has been released'
puts 'Disconnecting ...'
GoodData.disconnect