require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# setup all parameters for user input
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# assign to username
username = options[:username]
password = options[:password]
server = options[:server]

# variables for standard output
counter_ok = 0
counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# specify the tags to check here
tag = ['qa','test']

GoodData.with_connection(login: username, password: password, server: server) do |client|
    
       # get project context for both start and devel
       start = client.projects(options[:start])
       devel = client.projects(options[:devel])
       
       # for each tag select reports, order them and compare results
       tag.each do |tag|
       
       orig_reports = start.reports.select {|r| r.tag_set.include?(tag)}.sort_by(&:title)
       
       new_reports = devel.reports.select {|r| r.tag_set.include?(tag)}.sort_by(&:title)

       results = orig_reports.zip(new_reports).pmap do |reports|
           # compute both reports and add the report at the end for being able to print a report later
           reports.map(&:execute) + [reports.last]
       end
       
       # print report name and result true/false if the result is complete
       results.map do |res|
           orig_result, new_result, new_report = res
           
           if orig_result != new_result

           then

           counter_err += 1
           error_details = {
               :type => "ERROR",
               :url => server + '#s=/gdc/projects/' + devel.pid + '|analysisPage|head|' + new_report.uri,
               :api => server + new_report.uri,
               :message => "New report result is different."
           }
           
           # save detail to the array
           err_array.push(JSON.generate(error_details))
           
           # count OK objects
           else
           
           counter_ok += 1
           
           end
           
       end
       
    end

  # prepare part of the results
  $result.push({:section => 'Compare report results', :OK => counter_ok, :ERROR => counter_err, :output => err_array})

  puts $result.to_json

end

GoodData.disconnect
