# This script checks if there are some data from yesterday
# You need to use two extra variables ATTRIBUTE -a and TIME -t
# 1. The ATTRIBUTE must to be filled by uri of some attribute like an ID (Orders) in this format: /gdc/md/projectspid/obj/1664
# 2. The TIME -t must to be filled by with attribute from time dimension.
# For yestreday it's "Date (your time dimension)", for previous month it's "Month/Year (your time dimension)"
# again use the uri in this format: /gdc/md/projectspid/obj/1663
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
  opts.on('-a', '--attribute ATTRIBUTE', 'Attribute') { |v| options[:attribute] = v }
  opts.on('-t', '--time TIME', 'Time') { |v| options[:time] = v }

end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]
pid = options[:devel]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
attribute = options[:attribute]
time = options[:time]

counter_ok = 0
counter_err = 0
result_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off
GoodData.with_connection(login: username, password: password, server: server) do |client|
  # connect to project
  GoodData.with_project(pid) do |project|
metric = project.add_measure 'SELECT COUNT(['+  attribute +']) WHERE ['+  time +'] = PREVIOUS',
     title: 'Test the data'
     metric.save
begin
if metric.execute.to_s == '' then
  counter_err += 1
  result_array.push(error_details = {
      :type => "ERROR",
      :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + metric.uri,
      :api => server + metric.uri,
      :title => project.title,
      :description => 'There are no data from yesterday.'
      })
else
  counter_ok += 1
  result_array.push(error_details = {
      :type => "INFO",
      :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + metric.uri,
      :api => server + metric.uri,
      :title => project.title,
      :description => 'There are some data from yesterday.'
      })
end
rescue
  counter_err += 1
  result_array.push(error_details = {
      :type => "ERROR",
      :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + metric.uri,
      :api => server + metric.uri,
      :title => project.title,
      :description => 'There is problem with the metric. It is uncomputable.'
      })
end
metric.delete
$result.push({:section => "The result if there are some data from yesterday.", :OK => counter_ok, :ERROR => counter_err, :output => result_array})

end
  puts $result.to_json
end
  GoodData.disconnect
