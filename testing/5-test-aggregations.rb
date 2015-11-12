require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# get setup for user input parameters
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and project ids from parameters
username = options[:username]
password = options[:password]
start = options[:start]
devel = options[:devel]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# specify aggregations to check
aggregations = [:sum,:avg,:median,:min,:max]
#aggregations = [:sum]

puts 'Connecting to GoodData...'
puts 'Testing fact aggregations between Start and Devel projects.'
puts 'It might took a while...please wait'

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|
    GoodData.with_project(start) do |project|
        
        # compute the aggregations for all fact in start project
        $start_results = {}
            project.facts.each do |fact|
                aggregations.each do |aggr|
                    metric = fact.create_metric(:title => "VALIDATION - #{aggr} of [#{fact.identifier}]", :type => aggr)
                    res = metric.execute
                    $start_results[metric.title] = res
                end
            end
            #    puts $start_results
    end
    
    GoodData.with_project(devel) do |project|
        
        # compute the aggregations for all fact in devel project
        $devel_fact_results = {}
        project.facts.each do |fact|
            
            aggregations.each do |aggr|
                metric = fact.create_metric(:title => "VALIDATION - #{aggr} of [#{fact.identifier}]", :type => aggr)
                res = metric.execute
                $devel_fact_results[metric.title] = res
            end
        end
        
        #        puts $devel_fact_results
    end
    
    # compare results between projects
    $devel_fact_results.each do |key, value|
        if $start_results[key] != $devel_fact_results[key] then puts key.to_s + ' - NOT MATCH' else puts key.to_s + ' - CORRECT' end
    end
end

puts 'Disconnecting...'
GoodData.disconnect
