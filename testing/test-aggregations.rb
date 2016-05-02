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

# variables for standard output
counter_ok = 0
counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end

# specify aggregations to check
aggregations = [:sum, :avg, :median, :min, :max]
#aggregations = [:sum]

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|
  GoodData.with_project(start) do |project|

    # compute the aggregations for all fact in start project
    $start_results = {}
    project.facts.each do |fact|
      aggregations.each do |aggr|
        metric = fact.create_metric(:title => "#{fact.uri}", :type => aggr)
        res = metric.execute
        $start_results[metric.title] = res
      end
    end
  end

  GoodData.with_project(devel) do |project|

    # compute the aggregations for all fact in devel project
    $devel_fact_results = {}
    project.facts.each do |fact|

      aggregations.each do |aggr|
        metric = fact.create_metric(:title => "#{fact.uri}", :type => aggr)
        res = metric.execute
        $devel_fact_results[metric.title] = res
      end
    end
  end

  # compare results between projects
  $devel_fact_results.each do |key, value|
    if $start_results[key] != $devel_fact_results[key] then
      # count errors and prepare details to the array
      counter_err += 1
      err_array.push (error_details = {
          :type => "ERROR",
          :url => server + '/#s=/gdc/projects' + devel +'|objectPage|' + key.to_s,
          :api => server + key.to_s,
          :title => '', #TODO
          :description => "Aggregation is different"
      })

    else
      # count OK objects
      counter_ok += 1
    end
  end

  # prepare part of the results
  $result.push({:section => 'Compare aggregations between start and devel project', :OK => counter_ok, :ERROR => counter_err, :output => err_array})
  puts $result.to_json

end

GoodData.disconnect
