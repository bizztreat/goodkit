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

# change the tags to check here
tag = 'preview'

puts 'Connecting to GoodData...'

GoodData.with_connection(username, password) do |client|
    
    
    #start = client.projects(options[:start])
    devel = client.projects(options[:devel])
    #devel = client.projects('x1c6gsmxhr84usnhww03s6ecx3625279')
    #start = client.projects('t3m4hv0v5vrysctjqax88t2q2346t6vd')
    
    # We assume that reports have unique name inside a project
    
    puts '--- --- --- --- '
    puts 'Reports that contains PREVIEW metrics and are not tagged PREVIEW:'
    
        metrics = devel.metrics.select {|m| m.tag_set.include?(tag)}.sort_by(&:title)
        
        metrics.each do |met|
            
            reports = met.usedby
        
        #puts 'Metric: ' + met.title + ' (https://secure.gooddata.com' + met.uri + ')'
            
            reports.select  {|report| report["category"] == 'report'}.each { |r|
                    # get only report objects and extract tags
                    obj = GoodData::get(r["link"])
                    
                    # check whether reports include preview tag
                    # puts obj['report']['meta']['title']
                    if !obj['report']['meta']['tags'].include? "preview" then
                        puts "-- https://secure.gooddata.com#{obj['report']['meta']['uri']}"
                    end
                }
        end
        
        puts '--- --- --- --- '
        puts 'Metrics that are PREVIEW but not in specific folder:'
        
        
        metrics.each do |met|
        
        folder = met.content["folders"]
        
        if folder.nil? then
                        puts 'Metric: ' + met.title + ' (https://secure.gooddata.com' + met.uri + ')'
                       else
                        obj = GoodData::get(folder[0])
                        #puts obj['folder']['meta']['title']
                            if !obj['folder']['meta']['title'].include? "ZOOM Preview" then puts 'Metric: ' + met.title + ' (https://secure.gooddata.com' + met.uri + ')' end
        end
        
        end
        
        reports = devel.reports.select {|m| m.tag_set.include?(tag)}.sort_by(&:title)

        puts '--- --- --- --- '
        puts 'Reports that are PREVIEW but not in specific folder:'

        reports.each do |rep|
            

            folders = rep.content["domains"]
        
            if folders.nil? then
                puts 'Report: ' + rep.title + ' (https://secure.gooddata.com' + rep.uri + ')'
            else
                    obj = GoodData::get(folders[0])
                    # puts obj['domain']['meta']['title']
                    if !obj['domain']['meta']['title'].include? "ZOOM Preview" then puts puts 'Report: ' + rep.title + ' (https://secure.gooddata.com' + rep.uri + ')'
                    end
            end
        end
        
        puts '--- --- --- --- '
        puts 'Reports that are tagged preview and are on not Zoom PREVIEW dashboards:'
    
        reports.each do |rep|
        
        using_reports = rep.usedby
        
        #puts reports
        
        using_reports.select  {|dash| dash["category"] == 'projectDashboard'}.each { |d|
            # get only report objects and extract tags
            obj = GoodData::get(d["link"])
            
            # check whether reports include preview tag
            #puts obj['projectDashboard']['meta']['title']
            
            if !obj['projectDashboard']['meta']['title'].include? "Zoom preview" then
                puts "https://secure.gooddata.com#{rep.uri}"
            end
            
        }

        end

end

puts 'Disconnecting...'
GoodData.disconnect
