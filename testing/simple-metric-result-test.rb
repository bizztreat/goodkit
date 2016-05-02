#Testing Report results between Start and Devel projects.
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# define options for script configuration
options = {}
OptionParser.new do |opts|

    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-d', '--develproject NAME', 'Devel Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
    opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
    opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }
end.parse!

# get credentials from input parameters
username = options[:username]
password = options[:password]
devel = options[:devel]
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

# variables for script results
result_array = []
$result = []

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|

       # get the project context using Project ID from user input
       devel_project = client.projects(devel)

       # check all metrics according to tag's rules
       devel_project.metrics.each do |m|

         if incl.to_s == '' || !(m.tag_set & incl).empty? then
           if excl.to_s == '' || (m.tag_set & excl).empty? then

             # push the result to result_array
             result_array.push(error_details = {
                 :type => "INFO",
                 :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + m.uri,
                 :api => server + m.uri,
                 :title => m.title,
                 :description => 'Results of the metric ('+ m.title + ') is: ' + m.execute.to_s
             })

            end
          end
       end
    #save errors in the result variable
    $result.push({:section => 'Metric results between Start and Devel projects.', :OK => 0, :ERROR => 0, :output => result_array})
  end

#print out the result
puts $result.to_json

GoodData.disconnect
