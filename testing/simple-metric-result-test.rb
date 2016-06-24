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
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for standard output
count_info = 0
count_error = 0
output = []
$result = []

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

development_project.metrics.each do |metric|
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?

      begin
        output.push(details = {
            :type => 'INFO',
            :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
            :api => server + metric.uri,
            :title => metric.title,
            :description => 'Results of the metric ('+ metric.title + ') is: ' + metric.execute.to_s
        })
        count_info += 1
      rescue
        output.push(details = {
            :type => 'ERROR',
            :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
            :api => server + metric.uri,
            :title => metric.title,
            :description => 'Results of the metric ('+ metric.title + ') is uncomputable.'
        })
        count_error += 1
      end
    end
  end
end

$result.push({:section => 'Metric results between Start and Development projects.', :OK => 0, :INFO => count_info, :ERROR => count_error, :output => output})
puts $result.to_json

GoodData.disconnect
