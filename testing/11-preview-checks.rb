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
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

counter_ok = 0
counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# change the tags to check here
tag = 'preview'

GoodData.with_connection(login: username, password: password, server: server) do |client|
    
    # get the devel project context
    devel = client.projects(options[:devel])
    
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
                        puts "-- " + server + "/#{obj['report']['meta']['uri']}"
                        
                        counter_err += 1
                        err_array.push(error_details = {
                                       :type => "ERROR",
                                       :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + "/#{obj['report']['meta']['uri']}",
                                       :api => server + "/#{obj['report']['meta']['uri']}",
                                       :message => "Report not tagged as preview."
                                       })
                    end
                }
        end
        
        # prepare part of the results
        $result.push({:section => 'Reports contains preview metric, not tagged as Preview', :OK => devel.metrics.count - counter_err, :ERROR => counter_err, :output => err_array})
        
        counter_err = 0

        # get all metrics
        metrics.each do |met|
        
        # get folder part of the metric metadata
        folder = met.content["folders"]
        
        # check for the correct folder or if folder is not set print the metric
        if folder.nil? then
                                counter_err += 1
                                err_array.push(error_details = {
                                               :type => "ERROR",
                                               :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + met.uri,
                                               :api => server + met.uri,
                                               :message => "Metric is not in folder."
                                               })
                       
                       else
                        obj = GoodData::get(folder[0])
                        #puts obj['folder']['meta']['title']
                            if !obj['folder']['meta']['title'].include? "ZOOM Preview" then
                                
                                counter_err += 1
                                err_array.push(error_details = {
                                                   :type => "ERROR",
                                                   :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + met.uri,
                                                   :api => server + met.uri,
                                                   :message => "Metric is not in Zoom Preview folder."
                                                   })
                            end
            end
        
        end
        
        # push result to the result array
        $result.push({:section => 'Metric is not in specific Zoom Preview folder or in any folder.', :OK => devel.metrics.count - counter_err, :ERROR => counter_err, :output => err_array})
        
        # reset counter
        counter_err = 0

        # get all reports for given tag
        reports = devel.reports.select {|m| m.tag_set.include?(tag)}.sort_by(&:title)

        # for each report
        reports.each do |rep|
            
            # get foler/domain part of the metadata
            folders = rep.content["domains"]
        
            # check if report is in preview folder/domain
            if folders.nil? then
                
                counter_err += 1
                err_array.push(error_details = {
                               :type => "ERROR",
                               :url => server + '/#s=/gdc/projects/' + devel.pid + '|analysisPage|' + rep.uri,
                               :api => server + rep.uri,
                               :message => "Reports is not in any folder"
                               })
            
            else
                    obj = GoodData::get(folders[0])
                    # puts obj['domain']['meta']['title']
                    if !obj['domain']['meta']['title'].include? "ZOOM Preview" then
                        
                            counter_err += 1
                            err_array.push(error_details = {
                                           :type => "ERROR",
                                           :url => server + '/#s=/gdc/projects/' + devel.pid + '|analysisPage|' + rep.uri,
                                           :api => server + rep.uri,
                                           :message => "Reports is not in Zoom Preview folder"
                                           })
                    end
            end
        end
        
        # push result to the result array
        $result.push({:section => 'Reports not in specific Zoom Preview folder or in any folder.', :OK => devel.reports.count - counter_err, :ERROR => counter_err, :output => err_array})
        
        # reset counter
        counter_err = 0
        
        reports.each do |rep|
        
        # get all objects that use report
        using_reports = rep.usedby
        
        # select only dashboards from objects that used report
        using_reports.select  {|dash| dash["category"] == 'projectDashboard'}.each { |d|
            # get only report objects and extract tags
            obj = GoodData::get(d["link"])
            
            # check whether reports include preview tag
            if !obj['projectDashboard']['meta']['title'].include? "Zoom preview" then
                
                counter_err += 1
                err_array.push(error_details = {
                               :type => "ERROR",
                               :url => server + '/#s=/gdc/projects/' + devel.pid + '|analysisPage|' + rep.uri,
                               :api => server + rep.uri,
                               :message => "Reports is not on Preview dashboard"
                               })
                
            end
            
        }

        end

        $result.push({:section => 'Reports tagged Preview not in Preview dashboard', :OK => devel.reports.count - counter_err, :ERROR => counter_err, :output => err_array})

        puts $result.to_json

end

GoodData.disconnect
