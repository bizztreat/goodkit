#Testing Metric results between Start and Devel projects.
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# create parameters for user input
options = {}
OptionParser.new do |opts|

    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
    opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
    opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }

end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]
server = options[:server]
start = options[:start]
devel = options[:devel]
incl = options[:incl]
excl = options[:excl]

# make arrays from incl and excl parameters
if incl.to_s != ''
incl = incl.split(",")
end

if excl.to_s != ''
excl = excl.split(",")
end

# variables for script results
result_array = []
$result = []
counter_ok = 0

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# turn off GoodData logging
GoodData.logging_off

# connect to gooddata project
GoodData.with_connection(login: username, password: password, server: server) do |client|


       start_project = client.projects(start)
       devel_project = client.projects(devel)

       # get metric from start project  include and exclude tags
       orig_metrics = start_project.metrics.select {|r| incl.to_s == '' || !(r.tag_set & incl).empty?}.sort_by(&:title)
       orig_metrics =  orig_metrics.select {|r| excl.to_s == '' || (r.tag_set & excl).empty?}.sort_by(&:title)

        # get metrics from devel project include and exclude tags
       new_metrics = devel_project.metrics.select {|r| incl.to_s == '' || !(r.tag_set & incl).empty?}.sort_by(&:title)
       new_metrics = new_metrics.select {|r| excl.to_s == '' || (r.tag_set & excl).empty?}.sort_by(&:title)


       # compare results
       results = orig_metrics.zip(new_metrics).pmap do |metrics|
           # compute both metrics and add the metrics at the end for being able to print a metric later
           metrics.map(&:execute) + [metrics.last]
       end

       # print results for both metrics from start and devel
       results.map do |res|
           orig_result, new_result, new_metrics = res

         result_array.push({
           :type => "INFO",
           :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + new_metrics.uri ,
           :api => server + new_metrics.uri,
           :message => 'Results of the metric ('+ new_metrics.title + ') are in both projects equal.'
         })
         # count objects
         counter_ok += 1


       end

    #save errors in the result variable
    $result.push({:section => 'Metric results between Start and Devel projects.', :OK => counter_ok, :ERROR => 0, :output => result_array})

end

#print out the result
puts $result.to_json


GoodData.disconnect
