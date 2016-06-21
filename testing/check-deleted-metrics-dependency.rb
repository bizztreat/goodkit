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
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_excluded] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

counter_error = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
project = client.projects(development_project)

# get metric expression from development project
project.reports.each do |report|

  # check included and excluded tags
  if tags_included.empty? || !(report.tag_set & tags_included).empty?
    if (report.tag_set & tags_excluded).empty?

      # cache object which are current using on the report
      objects = report.definition.using

      # go through them
      objects.select { |object| object['category'] == 'metric' }.each do |object|

        metric = project.metrics(object['link'])

        # check if the metric is deleted
        if metric.deprecated

          counter_error += 1
          output.push(error_details = {
              :type => 'ERROR',
              :url => server + '/#s=/gdc/projects/' + development_project + '|objectPage|' + metric.uri,
              :api => server + metric.uri,
              :title => metric.title,
              :description => 'This report\'s metric has been deleted.'
          })
        end
      end
    end
  end

  if counter_error > 0
    $result.push({:section => 'This report "' + report.title + '" contains deleted metrics', :OK => 0, :INFO => 0, :ERROR => counter_error, :output => output})
    counter_error = 0
  end
end

puts $result.to_json

client.disconnect
