require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# collect all parameters from user
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get parameters from input for conection and for project id
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]

# variables for standard output
counter_ok = 0
counter_err = 0
err_array = []
result = []

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

GoodData.with_connection(username, password) do |client|

   # check if any datasets is empty -> print the dataset name
   GoodData.with_project(devel) do |project|
           blueprint = project.blueprint
           blueprint.datasets.each do |dataset|
               count = dataset.count(project)
               if (count.to_i < 1) then
                   # count errors and prepare details to the array
                   counter_err += 1
                   error_details = {
                       :type => "ERROR",
                       :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + dataset.uri,
                       :api => server + dataset.uri,
                       :message => "Dataset it empty."
                   }
                   
                   # save detail to the array
                   err_array.push(JSON.generate(error_details))
                   
                   # count OK objects
                   else counter_ok += 1
               end
           end
       end
  
  # prepare part of the results
   result.push({:section => 'Empty datasets check', :OK => counter_ok, :ERROR => counter_err, :output => err_array})
   
   puts result.to_json

end

GoodData.disconnect
