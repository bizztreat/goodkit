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

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for standard output
counter_info = 0
counter_error = 0
counter_error_2 = 0
output_1 = []
output_2 = []
output_3 = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)
metrics = {}

development_project.metrics.pmap do |metric|
  metrics.store(metric.title, metric.expression)
end

development_project.facts.each do |fact|

  if tags_included.empty? || !(fact.tag_set & tags_included).empty?
    if (fact.tag_set & tags_excluded).empty?

      if metrics.include? fact.title
        if metrics[fact.title] == 'SELECT [' + fact.uri + ']'
          output_1.push(details = {
              :type => 'INFO',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + fact.uri,
              :api => server + fact.uri,
              :title => fact.title,
              :description => 'The fact "' + fact.title + '" has simple metric.'
          })
          counter_info += 1
        else
          output_2.push(details = {
              :type => 'ERROR',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + fact.uri,
              :api => server + fact.uri,
              :title => fact.title,
              :description => 'The fact "' + fact.title + '" has a metric but not in simple format.'
          })
          counter_error += 1
        end
      else
        output_3.push(details = {
            :type => 'ERROR',
            :url => server + '/#s=' + development_project.uri + '|objectPage|' + fact.uri,
            :api => server + fact.uri,
            :title => fact.title,
            :description => 'The fact "' + fact.title + '" does not have any metric.'
        })
        counter_error_2 += 1
      end
    end
  end

end

$result.push({:section => 'The facts have simple metric.', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output_1})
$result.push({:section => 'The facts have a metric but not in simple format.', :OK => 0, :INFO => 0, :ERROR => counter_error, :output => output_2})
$result.push({:section => 'The facts do not have any metric.', :OK => 0, :INFO => 0, :ERROR => counter_error_2, :output => output_3})
puts $result.to_json

client.disconnect
