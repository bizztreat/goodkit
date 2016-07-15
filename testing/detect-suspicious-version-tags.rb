#This script check metric's version tags in decimal format "1.1"
#The error is report when the development metric has lower version tag then start metric
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'rubygems'
require 'json'

# prepare all parameters options
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-s', '--start_project ID', 'Start Project') { |v| options[:start_project] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }
end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
start_project = options[:start_project]
development_project = options[:development_project]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for script results
output = []
$result = []
counter_ok = 0
counter_error = 0

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development and start GoodData projects
start_project = client.projects(start_project)
development_project = client.projects(development_project)

  # select start project metrics and include and exclude tags
  start_project_metrics = start_project.metrics.select { |metric| (tags_included.empty? || !(metric.tag_set & tags_included).empty?) && (metric.tag_set & tags_excluded).empty? }.sort_by(&:title)

  # select development project metrics and include and exclude tags
  development_project_metrics = development_project.metrics.select { |metric| (tags_included.empty? || !(metric.tag_set & tags_included).empty?) && (metric.tag_set & tags_excluded).empty? }.sort_by(&:title)

  # iterate throught every metric
  start_project_metrics.peach do |metric_start|
    development_project_metrics.peach do |metric_dev|
      #do the metrics with the same title
      if metric_start.title == metric_dev.title then
        #prepare tag sets for both metrics
        start_tags = metric_start.tags.to_s.split(' ')
        dev_tags = metric_dev.tags.to_s.split(' ')
        #go trought the metric's tags
        start_tags.each do |s|
          #Check format if it's version tag
          if s =~ /\d+\.\d+?/
            then
            dev_tags.each do |d|
              #Check format if it's version tag
              if d =~ /\d+\.\d+?/
                then
                #Compare version tags
                if d < s
                  then
                  #Report error if the version tag of devel metric is lower then start metric
                  counter_error += 1
                  output.push(details = {
                    :type => 'ERROR',
                    :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + metric_dev.uri,
                    :api => server + metric_dev.uri,
                    :title => metric_dev.title,
                    :description => 'The development metric is suspicious.'
                    })
                end
              end
            end
          end
        end
      end

end
end
$result.push({:section => 'The suspicious metrics according to their tags.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

  GoodData.disconnect
