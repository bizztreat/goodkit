#Checking for non-used facts and attributes
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# initiate parameters for user input
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# check all parameters
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end

counter_ok = 0
counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|

  # prepare hashes and arrays for results
  $devel_metrics = Hash.new
  $start_metrics = Hash.new

  # connect to project context
  project = client.projects(devel)

  # Find unused attributes
  # for each attribute
  project.attributes.each do |attr|

    num_objects = 0
    objects = attr.usedby
    objects.select { |attribute| attribute["category"] == 'metric' }.each { |r|
      # get only metric objects
      num_objects += 1
    }

    objects.select { |attribute| attribute["category"] == 'report' }.each { |r|
      # get only report objects
      num_objects += 1
    }

    # safe the result if there is ZERO objects that are using the attribute
    if num_objects == 0 then
      err_array.push(error_details = {
          :type => "ERROR",
          :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + attr.uri,
          :api => server + attr.uri,
          :title => attr.title,
          :description => 'This attribute ('+ attr.title + ') is not used by any object'
      })
      counter_err += 1
    else
      counter_ok += 1
    end
  end

  #save errors in the result variable
  $result.push({:section => 'Attributes which have not been used in any object (metric or report).', :OK => counter_ok, :ERROR => counter_err, :output => err_array})

  #reset variables for counting errors
  err_array = []
  counter_ok = 0
  counter_err = 0

  # Find unused facts
  # for each fact do the check
  project.facts.each do |fact|

    num_objects = 0
    objects = fact.usedby
    objects.select { |fact| fact["category"] == 'metric' }.each { |r|
      # get only metric objects
      num_objects += 1
    }

    objects.select { |fact| fact["category"] == 'report' }.each { |r|
      # get only report objects
      num_objects += 1
    }

    # safe the result if there is ZERO objects that are using the fact
    if num_objects == 0 then

      err_array.push(error_details = {
          :type => "ERROR",
          :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + fact.uri,
          :api => server + fact.uri,
          :title => fact.title,
          :description => 'This fact ('+ fact.title + ') is not used by any object'
      })
      counter_err += 1
    else
      counter_ok += 1
    end
  end
  #save errors in the result variable
  $result.push({:section => 'Facts which have not been used in any object (metric or report).', :OK => counter_ok, :ERROR => counter_err, :output => err_array})

end
#print out the result
puts $result.to_json

GoodData.disconnect
