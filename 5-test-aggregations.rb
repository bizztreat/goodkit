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
aggregations = [:sum,:avg,:median,:min,:max]
#aggregations = [:sum]


# testing master project ID = y672cuxov5x6swn64tlaz5jwcrez0wid

puts 'Connecting to GoodData...'
puts 'Testing fact aggregations between Start and Devel projects.'

GoodData.with_connection(username, password) do |client|
    GoodData.with_project(start) do |project|
        
        $start_results = {}
            project.facts.each do |fact|
                aggregations.each do |aggr|
                    metric = fact.create_metric(:title => "VALIDATION - #{aggr} of [#{fact.identifier}]", :type => aggr)
                    res = metric.execute
                    $start_results[metric.title] = res
                    puts res
                end
            end
            puts $start_results
    end
    
    GoodData.with_project(devel) do |project|
        
        $devel_fact_results = {}
        project.facts.each do |fact|
            
            aggregations.each do |aggr|
                metric = fact.create_metric(:title => "VALIDATION - #{aggr} of [#{fact.identifier}]", :type => aggr)
                res = metric.execute
                $devel_fact_results[metric.title] = res
                puts res
            end
        end
        
        puts $devel_fact_results
    end
    
    $start_results.each do |key, value| 
        if $start_results[key] != $devel_fact_results[key] then puts key.to_s + ' - NOT MATCH' else puts key.to_s + ' - CORRECT' end
    end
end

puts 'Disconnecting...'
GoodData.disconnect
