#Check that there is no metric that is a "base" metric and uses fact
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
err_array = []
result_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

GoodData.with_connection(login: username, password: password, server: server) do |client|


  # get the devel project context
  devel = client.projects(pid)

  devel.metrics.peach do |m|
    if incl.to_s == '' || !(m.tag_set & incl).empty? then
      if excl.to_s == '' || (m.tag_set & excl).empty? then
          #check if there is any fact in metric definition
          if m.using.select { |object| object['category'] == 'fact' } != [] then
            #check if the metric using fact is in simple metric format "SELECT 'MetricNAME'"
            if m.expression == "SELECT [" + m.using.select { |object| object['category'] == 'fact' }.first["link"] + "]" then
              counter_ok += 1
              #push correct metric to result array
              result_array.push(error_details = {
                  :type => "INFO",
                  :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + m.uri,
                  :api => server + m.uri,
                  :title => m.title,
                  :description => 'The metric "' + m.title + '" uses a fact but it is a simple metric.'
                  })
            else
            #Check if the facts are in metric definition or they are for example used by metrics from the definition
              m.using.select { |object| object['category'] == 'fact' }.each do |f|
                    if m.expression.include? f["link"] then
                      counter_err += 1
                      #push error metric to error array
                      err_array.push(error_details = {
                          :type => "ERROR",
                          :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + m.uri,
                          :api => server + m.uri,
                          :title => m.title,
                          :description => 'The metric "' + m.title + '" uses a fact and it is not in simple metric format!'
                      })
                      break # finish the look if there is error on the metric
                    end
                end
            end
          end
      end
    end
  end
  #push the result to the result file
  $result.push({:section => "The facts have simple metric.", :OK => counter_ok, :ERROR => 0, :output => result_array})
  $result.push({:section => "The facts have a metric but not in simple format.", :OK => 0, :ERROR => counter_err, :output => err_array})
  puts $result.to_json
  end
  GoodData.disconnect
