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
  opts.on('-t', '--exclude EXCLUDE', 'Checked tag') { |v| options[:tag] = v }
end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')
tag = options[:tag].to_s.empty? ? 'cisco' : options[:tag]

# variables for script results
result_array = []
counter_ok = 0
counter_error = 0
$result = []
stop = 0

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

development_project.metrics.each do |metric|

  # check included and excluded tags
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?

      tag_set = metric.tags.to_s.split(' ')

      # go through metrics
      objects = metric.using
      objects.select { |object| object['category'] == 'metric' }.each do |object|
        object = development_project.metrics(object['link'])
        unless object.tags.to_s.split(' ').include?(tag)
          stop = 1
        end
      end

      # go through attributes
      objects = metric.using
      objects.select { |object| object['category'] == 'attribute' }.each do |object|
        object = development_project.attributes(object['link'])
        unless object.tags.to_s.split(' ').include? tag
          stop = 1
        end
      end

      # if all objects include the tag, set the tag for metric as well
      if stop == 0
        metric.add_tag(tag)
        metric.save

        # push the result to result_array
        if tag_set.include?(tag)
          result_array.push(details = {
              :type => 'OK',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
              :api => server + metric.uri,
              :title => metric.title,
              :description => 'The tag set of metric ('+ metric.title + ') already include the tag ('+ tag + ').'
          })
          counter_ok += 1
        else
          result_array.push(details = {
              :type => 'ERROR',
              :url => server + '/#s=/gdc/projects/' + development_project.uri + '|objectPage|' + metric.uri,
              :api => server + metric.uri,
              :title => metric.title,
              :description => 'The tag "'+ tag + '" has been added to the tag set of the metric.'
          })
          counter_error += 1
        end
      end
    end
  end
end

$result.push({:section => 'Tag sets of these metrics have been checked and changed.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => result_array})

# reset variables
result_array = []
counter_ok = 0
counter_error = 0
stop = 0

development_project.reports.each do |report|

  # check included and excluded tags
  if tags_included.empty? || !(variable.tag_set & tags_included).empty?
    if (variable.tag_set & tags_excluded).empty?

      # tag set of original report
      tag_set = report.tags.to_s.split(' ')

      #go through report's metrics
      objects = report.using
      objects.select { |object| object['category'] == 'metric' }.each do |object|
        object = development_project.metrics(object['link'])
        unless object.tags.to_s.split(' ').include? tag
          stop = 1
        end
      end

      #go through report's attributes
      objects = report.using
      objects.select { |object| object['category'] == 'attribute' }.each do |object|
        object = development_project.attributes(object['link'])
        unless object.tags.to_s.split(' ').include? tag
          stop = 1
        end
      end

      # if all objects include the tag, set the tag for metric as well
      if stop == 0
        report.add_tag(tag)
        report.save

        # push the result to result_array
        if tag_set.include?(tag)
          result_array.push(details = {
              :type => 'OK',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + report.uri,
              :api => server + report.uri,
              :title => report.title,
              :description => 'The tag set of report ('+ report.title + ') already include the tag ('+ tag + ').'
          })
          counter_ok += 1
        else
          result_array.push(details = {
              :type => 'ERROR',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + report.uri,
              :api => server + report.uri,
              :title => report.title,
              :description => 'The tag ('+ tag + ') has been added to the tag set of the metric.'
          })
          counter_error += 1
        end
      end
    end
  end
end

$result.push({:section => 'Tag sets of these reports have been checked and changed.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => result_array})
puts $result.to_json

client.disconnect
