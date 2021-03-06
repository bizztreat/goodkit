require 'gooddata'
require 'optparse'

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
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]

# variables for standard output
counter_ok = 0
counter_error = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

blueprint = development_project.blueprint
blueprint.datasets.peach do |dataset|

  # creates a metric which return number of lines in dataset
  lines = dataset.count(development_project)
  if lines.to_i < 1

    object_dataset = GoodData::Dataset[dataset.id, {:client => client, :project => development_project}] #TODO remove
    output.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|objectPage|' + object_dataset.uri,
        :api => server + object_dataset.uri,
        :title => dataset.title,
        :description => 'Dataset it empty.'
    })
    counter_error += 1
  else
    counter_ok += 1
  end
end

$result.push({:section => 'Empty datasets check', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
