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
    
end.parse!

#username = ''
#password = ''
username = options[:username]
password = options[:password]

start = options[:start]
devel = options[:devel]
#start = 'x1c6gsmxhr84usnhww03s6ecx3625279'
#devel = 't3m4hv0v5vrysctjqax88t2q2346t6vd'

#testing master project ID = y672cuxov5x6swn64tlaz5jwcrez0wid

puts 'Connecting to GoodData...'
puts 'Checking for updated metrics...'

GoodData.with_connection(username, password) do |client|
    
    $devel_metrics = Hash.new
    $start_metrics = Hash.new
    $updated_metrics = []
    
    GoodData.with_project(devel) do |project|
        
        project.metrics.each do |metric|
            $devel_metrics.store(metric.uri.gsub(devel, "pid"), metric.expression.gsub(devel, "pid"))
            #puts $devel_metrics.keys
        end
        
    end
    
    GoodData.with_project(start) do |project|
        
        project.metrics.each do |metric|
            $start_metrics.store(metric.uri.gsub(start, "pid"), metric.expression.gsub(start, "pid"))
            # puts $start_metrics.keys
        end
        
    end

    #puts 'UPDATED METRICS'
    $devel_metrics.each_key { |key|
      
      if $start_metrics[key] != $devel_metrics[key] then $updated_metrics.push(key.gsub("pid",devel)) end
      #  puts $updated_metrics
        
    }
    
    project = client.projects(devel)
    
    $updated_metrics.each do |met|
        puts '------'
        metric = project.metrics(met)
        puts 'Title: ' + metric.title
        puts 'Link: http://secure.gooddata.com' + met
        
        puts '- Used in following reports:'
        objects = metric.usedby
        objects.select  {|report| report["category"] == 'report'}.each { |r|
            # get only report objects and extract tags
            obj = GoodData::get(r["link"])
            
            # check whether reports include preview tag
                puts '-- Title: ' + obj['report']['meta']['title']
                puts "https://secure.gooddata.com/#s=/gdc/projects/" + devel + "%7CanalysisPage%7Chead%7C" + obj['report']['meta']['uri']
                # puts "-- Link: https://secure.gooddata.com#{obj['report']['meta']['uri']}"
        }
        
        puts '- Used in following dashboards:'
        objects.select  {|dashboard| dashboard["category"] == 'projectDashboard'}.each { |r|
            # get only report objects and extract tags
            obj = GoodData::get(r["link"])
            
            # check whether reports include preview tag
            puts '-- Title: ' + obj['projectDashboard']['meta']['title']
            puts "https://secure.gooddata.com/#s=/gdc/projects/" + devel + "|projectDashboardPage|" + obj['projectDashboard']['meta']['uri']
            # puts "-- Link: https://secure.gooddata.com#{obj['projectDashboard']['meta']['uri']}"
        }
    end
    
    
end

puts 'Disconnecting...'
GoodData.disconnect
