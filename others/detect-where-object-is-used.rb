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
  opts.on('-o', '--object_identifier OBJECT', 'Object Identifier') { |v| options[:object_identifier] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server]
object_identifier = options[:object_identifier]


# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

counter_info = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

object = development_project.objects(object_identifier)

development_project.reports.peach do |report|
  if report.definition.using? object
    output.push(details = {
        :type => 'INFO',
        :url => server + '/#s=' + development_project.uri + '|analysisPage|head|' + report.uri,
        :api => server + report.uri,
        :description => 'The attribute "' + object.title + '" is being used in report "' + report.title + '".'
    })
    counter_info += 1
  end
end

$result.push({:section => 'The object <a href="' + server + '/#s=' + development_project.uri + '|objectPage|' + object.uri + '">' + object.title + '</a> report usage.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output})
puts $result.to_json

client.disconnect
