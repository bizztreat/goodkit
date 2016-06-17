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

    project.metrics.each do |metric|

      # check included and excluded tags
      if tags_included.empty? || !(metric.tag_set & tags_included).empty?
        if (metric.tag_set & tags_excluded).empty?

          # check that metric value contains deleted value
          if metric.pretty_expression.include? '[(empty value)]'

            output.push(error_details = {
                :type => 'ERROR',
                :url => server + '/#s=/gdc/projects/' + development_project + '|objectPage|' + metric.uri,
                :api => server + metric.uri,
                :title => metric.title,
                :description => 'Metric contains (delete value) ' + metric.pretty_expression
            })
            counter_error += 1
          else
            counter_ok += 1
          end
        end
      end
    end

    $result.push({:section => 'Metrics with Deleted Value', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
    puts $result.to_json

  end
end

GoodData.disconnect
