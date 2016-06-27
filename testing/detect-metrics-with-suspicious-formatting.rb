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
  opts.on('-f', '--format Format', 'Format') { |v| options[:format] = v }
  opts.on('-c', '--check Check', 'Check') { |v| options[:check] = v }
  opts.on('-t', '--title TITLE', 'Text in title') { |v| options[:title] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }

end.parse!

# get all parameters - username, password and project id
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

# allowed metric format (any difference formatting is counted as an error) for example: "#,##0%" Please youse "" for format!
format = options[:format]

# Do you want to combinate checking metric format with checking a name of metric? (true=yes, false=no). for example: true
check_text_in_title = options[:check]

# If you set up "check_text_in_title" to "true", a format of metrics will be check just for metrics containing "text_in_title" in their title!
text_in_title = options[:title]

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

# go parallel through all metrics in the project
development_project.metrics.pmap do |metric|

  # check included and excluded tags
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?

      # check just metric format or format and title together
      if ((metric.content['format'] != format) && !(check_text_in_title)) || ((metric.content['format'] != format) && (metric.title.include? text_in_title))
        output.push(details = {
            :type => 'ERROR',
            :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
            :api => server + metric.uri,
            :title => metric.title,
            :description => 'Suspicious metric formatting detected.'
        })
        counter_error += 1
      else
        counter_ok += 1
      end
    end
  end
end

# prepare part of the results
$result.push({:section => 'Suspicious metric´s formatting check.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
