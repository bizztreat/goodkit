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
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server]

# variables for standard output
counter_ok = 0
counter_error = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|

  # connect to development GoodData project
  GoodData.with_project(development_project) do |project|

    blueprint = project.blueprint
    blueprint.datasets.each do |dataset|

      # creates a metric which return number of lines in dataset
      lines = dataset.count(project)
      if lines.to_i < 1

        counter_error += 1
        object_dataset = GoodData::Dataset[dataset.id, {:client => client, :project => project}]
        output.push(error_details = {
            :type => 'ERROR',
            :url => server + '/#s=/gdc/projects/' + development_project + '|objectPage|' + object_dataset.uri,
            :api => server + object_dataset.uri,
            :title => dataset.title,
            :description => 'Dataset it empty.'
        })
      else
        counter_ok += 1
      end
    end
  end

  $result.push({:section => 'Empty datasets check', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
  puts $result.to_json

end

GoodData.disconnect
