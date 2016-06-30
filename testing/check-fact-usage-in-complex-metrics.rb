require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'rubygems'
require 'json'

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

development_project.metrics.peach do |metric|

  # check included and excluded tags
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?

      # check if there is any fact in metric definition
      unless metric.using.select { |object| object['category'] == 'fact' }.empty?

        # check if the metric using fact is in simple metric format 'SELECT 'fact'
        if metric.expression == 'SELECT [' + metric.using.select { |object| object['category'] == 'fact' }.first['link'] + ']'
          counter_ok += 1
        else

          # check if the facts are in metric definition or they are for example used by metrics from the definition
          metric.using.select { |object| object['category'] == 'fact' }.each do |fact|
            if metric.expression.include? fact['link']

              output.push(details = {
                  :type => 'ERROR',
                  :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
                  :api => server + metric.uri,
                  :title => metric.title,
                  :description => 'The metric "' + metric.title + '" uses a fact and it is not in simple metric format!'
              })
              counter_error += 1
            end
          end
        end
      end
    end
  end
end

$result.push({:section => 'The facts have a metric but not in simple format.', :OK => 0, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
