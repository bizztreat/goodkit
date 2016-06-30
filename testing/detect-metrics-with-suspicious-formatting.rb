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

# variables for standard output
counter_error = 0
output = []
$result = []
allowed_formats = {:Count => '#,##0', :Total => '#,##0', :Points => '#,##0.00', :Average => '#,##0', :% => '#,##0%'}

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# go parallel through all metrics in the project
development_project.metrics.map do |metric|

  # check included and excluded tags
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?

      # check metric format and title together
      allowed_formats.each do |title_substring, format|

        if (metric.title.include? title_substring.to_s) && (metric.content['format'] != format)
          unless (metric.title.include? 'Time') && (metric.content['format'] == '{{{60||0}}}:{{{1|60|00}}}')
            output.push(details = {
                :type => 'ERROR',
                :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
                :api => server + metric.uri,
                :title => metric.title,
                :description => 'Suspicious metric formatting detected. The ' + title_substring.to_s + ' metric must have format ' + format + ' not ' + metric.content['format']
            })
            counter_error += 1
            break
          end
        end
      end
    end
  end
end

$result.push({:section => 'Suspicious metric´s formatting check.', :OK => 0, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
