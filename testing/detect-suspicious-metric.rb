#MZ Detect suspicious metric
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }
end.parse!

# get all parameters - username, password and project id
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

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# extra variables
special = "()/\[]^+-"
regex = /[#{special.gsub(/./){|char| "\\#{char}"}}]/

# variables for standard output
counter_ok = 0
counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|

# connect to project
  GoodData.with_project(devel) do |project|
  # go through all metrics in the project
    project.metrics.pmap do |metric|
      if incl.to_s == '' || !(metric.tag_set & incl).empty? then
        if excl.to_s == '' || (metric.tag_set & excl).empty? then
    # check if the metric contains speceial characters which mean it's not just SELECT and a constant
      if not
      metric.expression =~ regex
        then

        # count errors and prepare details to the array
        counter_err += 1

        err_array.push(error_details = {
            :type => "ERROR",
            :title => metric.title,
            :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + metric.uri ,
            :api => server + metric.uri,
            :message => "Suspicious metric detected."
        })

      # count OK objects
      else counter_ok += 1

      end
    end
end
end
    # prepare part of the results
    $result.push({:section => 'Suspicious metrics check.', :OK => counter_ok, :ERROR => counter_err, :output => err_array})

    puts $result.to_json

  end
end
GoodData.disconnect
