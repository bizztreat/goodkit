require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'json'

options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# collect parameters for connection and for project variable
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]

counter_ok = 0
counter_err = 0
err_array = []
result = []

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

GoodData.logging_off

GoodData.with_connection(login: username, password: password, server: server) do |client|

    # connect to project
    GoodData.with_project(devel) do |project|
        
        # check all reports for missing tags
        project.reports.each do |report|
            
                tags = report.tags.gsub(/\s+/m, ' ').strip.split(" ")
                if
                
                !tags.any? { |tag| /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/.match(tag) }
                
                then
                
                 # count errors and prepare details to the array
                 counter_err += 1
                 error_details = {
                     :type => "ERROR",
                     :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + report.uri,
                     :api => server + report.uri,
                     :message => "Report does not have a version tag."
                 }
                 
                 # save detail to the array
                 err_array.push(JSON.generate(error_details))
                
                # count OK objects
                else counter_ok += 1
                
                end

        end
        
        # prepare part of the results
        result.push({:section => 'Reports without version tags', :OK => counter_ok, :ERROR => counter_err, :output => err_array})
        
        # check all metrics for missing tags
        project.metrics.each do |metric|
        
            tags = metric.tags.gsub(/\s+/m, ' ').strip.split(" ")
            if
                !tags.any? { |tag| /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/.match(tag) }
    
                then
                # count errors and prepare details to the array
                counter_err += 1
                error_details = {
                    :type => "ERROR",
                    :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + metric.uri,
                    :api => server + metric.uri,
                    :message => "Metric does not have a version tag."
                }
                
                # save detail to the array
                err_array.push(JSON.generate(error_details))
                
                # count OK objects
                else counter_ok += 1
            end
        
        end
        
        result.push({:section => 'Metrics without version tags', :OK => counter_ok, :ERROR => counter_err, :output => err_array})
        
        puts result.to_json
        
    end
    
end
GoodData.disconnect
