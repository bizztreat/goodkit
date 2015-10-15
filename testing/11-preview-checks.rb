require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# prepare all parameters options
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    
end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]

# change the tags to check here
tag = 'preview'

puts 'Connecting to GoodData...'

GoodData.with_connection(username, password) do |client|
    
    # get the devel project context
    devel = client.projects(options[:devel])
    
    
    puts '--- --- --- --- '
    puts 'Reports that contains PREVIEW metrics and are not tagged PREVIEW:'
    
        # get all metrics for given tag
        metrics = devel.metrics.select {|m| m.tag_set.include?(tag)}.sort_by(&:title)
        
        # for each metric
        metrics.each do |met|
            
            reports = met.usedby
        
            reports.select  {|report| report["category"] == 'report'}.each { |r|
                    # get only report objects and extract tags
                    obj = GoodData::get(r["link"])
                    
                    # check whether reports include preview tag
                    if !obj['report']['meta']['tags'].include? "preview" then
                        puts "-- https://secure.gooddata.com#{obj['report']['meta']['uri']}"
                    end
                }
        end
        
        puts '--- --- --- --- '
        puts 'Metrics that are PREVIEW but not in specific folder:'
        
        # get all metrics
        metrics.each do |met|
        
        # get folder part of the metric metadata
        folder = met.content["folders"]
        
        # check for the correct folder or if folder is not set print the metric
        if folder.nil? then
                        puts 'Metric: ' + met.title + ' (https://secure.gooddata.com' + met.uri + ')'
                       else
                        obj = GoodData::get(folder[0])
                        #puts obj['folder']['meta']['title']
                            if !obj['folder']['meta']['title'].include? "ZOOM Preview" then puts 'Metric: ' + met.title + ' (https://secure.gooddata.com' + met.uri + ')' end
        end
        
        end
        
        # get all reports for given tag
        reports = devel.reports.select {|m| m.tag_set.include?(tag)}.sort_by(&:title)

        puts '--- --- --- --- '
        puts 'Reports that are PREVIEW but not in specific folder:'

        # for each report
        reports.each do |rep|
            
            # get foler/domain part of the metadata
            folders = rep.content["domains"]
        
            # check if report is in preview folder/domain
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
        
        # get all objects that use report
        using_reports = rep.usedby
        
        # select only dashboards from objects that used report
        using_reports.select  {|dash| dash["category"] == 'projectDashboard'}.each { |d|
            # get only report objects and extract tags
            obj = GoodData::get(d["link"])
            
            # check whether reports include preview tag
            if !obj['projectDashboard']['meta']['title'].include? "Zoom preview" then
                puts "https://secure.gooddata.com#{rep.uri}"
            end
            
        }

        end

end

puts 'Disconnecting...'
GoodData.disconnect
