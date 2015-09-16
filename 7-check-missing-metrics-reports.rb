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
puts 'Checking for missing reports and metrics.'

GoodData.with_connection(username, password) do |client|
    
    start_reports = []
    devel_reports = []
    start_metrics = []
    devel_metrics = []
    
    GoodData.with_project(devel) do |project|
        
        project.reports.each do |report|
                devel_reports.push(report.title)
        end
        
        project.metrics.each do |metric|
                devel_metrics.push(metric.title)
        end
        
    end
    
    GoodData.with_project(start) do |project|
        
        project.reports.each do |report|
            start_reports.push(report.title)
        end
        
        project.metrics.each do |metric|
            start_metrics.push(metric.title)
        end
        
    end
    
    puts 'Metrics missing in Devel Project:'
    metrics_diff = start_metrics - devel_metrics
    if metrics_diff.empty? then puts 'NOTHING IS MISSING' else puts metrics_diff end
    
    puts 'Reports missing in Devel Project:'
    
    reports_diff = start_reports - devel_reports
    if reports_diff.empty? then puts 'NOTHING IS MISSING' else puts reports_diff end
    
end

puts 'Disconnecting...'
GoodData.disconnect
