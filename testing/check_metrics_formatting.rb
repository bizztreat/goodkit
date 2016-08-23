require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_excluded] = v }
  opts.on('-t', '--patterns PATTERNS', 'Patterns') { |v| options[:patterns] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')
patterns = options[:patterns].to_s.split(';')

# variables for standard output
counter_error = 0
counter_ok = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# do metrics
development_project.metrics.peach do |metric|
  # ignore more lines metric formatting
if !metric.content['format'].to_s.include? ";" then
 # check if the metric format is allowed
if !patterns.include? metric.content['format'].to_s
  then
    #push the error
    counter_error += 1
    output.push(details = {
      :type => 'ERROR',
      :url => server + '#s=' + development_project.uri + '|objectPage|' + metric.uri,
      :api => server + metric.uri,
      :title => metric.title,
      :description => 'The metric formatting is not allowed.'
})
  else
    counter_ok += 1
end
end
end
#push the results
$result.push({:section => 'The list of metrics with not allowed formatting.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})


# result as json_file
puts $result.to_json

client.disconnect
