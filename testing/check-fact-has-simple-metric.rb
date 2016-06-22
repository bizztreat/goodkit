#The script is checking all facts in the project if they have metric in format "SELECT 'MetricName'"
#There are three options:
# 1 the fact has a metric with the same name and the metric is in correct format
# 2 the fact has a metric with the same name but the metric is not in simple format
# 3 the fact does not have any metric

require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'rubygems'
require 'json'

# prepare all parameters options
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }

end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]
pid = options[:devel]
server = options[:server]
incl = options[:incl]
excl = options[:excl]

# make arrays from incl and excl parameters
if incl.to_s != ''
  incl = incl.split(",")
end

if excl.to_s != ''
  excl = excl.split(",")
end

# if whitelabel is not specified set to default domain
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end
counter_ok = 0
counter_err = 0
counter_err2 = 0
err_array = []
err_array2 = []
result_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

GoodData.with_connection(login: username, password: password, server: server) do |client|


  # get the devel project context
  devel = client.projects(pid)
  metrics = {}
  devel.metrics.pmap do |metric|
  metrics.store(metric.title, metric.expression)
  end
  devel.facts.each do |f|
    if incl.to_s == '' || !(f.tag_set & incl).empty? then
      if excl.to_s == '' || (f.tag_set & excl).empty? then
          if metrics.include? f.title then
            if  metrics[f.title] == "SELECT [" + f.uri + "]" then
              counter_ok += 1
              result_array.push(error_details = {
                  :type => "INFO",
                  :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + f.uri,
                  :api => server + f.uri,
                  :title => f.title,
                  :description => 'The fact"' + f.title + '" has simple metric.'
                  })
                else
                    counter_err += 1
                  err_array.push(error_details = {
                      :type => "ERROR",
                      :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + f.uri,
                      :api => server + f.uri,
                      :title => f.title,
                      :description => 'The fact "' + f.title + '" has a metric but not in simple format.'
                  })
            end
          else
              counter_err2 += 1
            err_array2.push(error_details = {
                :type => "ERROR",
                :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + f.uri,
                :api => server + f.uri,
                :title => f.title,
                :description => 'The fact "' + f.title + '" does not have any metric.'
            })
          end
      end
    end

  end
    #push the result to the result file
    $result.push({:section => "The facts have simple metric.", :OK => counter_ok, :ERROR => 0, :output => result_array})
    $result.push({:section => "The facts have a metric but not in simple format.", :OK => 0, :ERROR => counter_err, :output => err_array})
    $result.push({:section => "The facts do not have any metric.", :OK => 0, :ERROR => counter_err2, :output => err_array2})

  puts $result.to_json
  end
  GoodData.disconnect
