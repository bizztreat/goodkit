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
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

counter_error = 0
output = []
$result = []

# change the tag and the name to check here
tag = 'preview'
name_starting= 'ZOOM Preview - '

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# get all metrics for given tag
metrics = development_project.metrics.select { |metric| metric.tag_set.include?(tag) }.sort_by(&:title)

metrics.each do |metric|
  reports = metric.usedby

  reports.select { |report| report['category'] == 'report' }.each do |report|

    # get only report objects and extract tags
    object = GoodData::get(report['link'])

    # check included and excluded tags
    if tags_included.empty? || !(object.tag_set & tags_included).empty?
      if (object.tag_set & tags_excluded).empty?

        # check whether reports include preview tag
        unless object['report']['meta']['tags'].include? 'preview'

          counter_error += 1
          output.push(details = {
              :type => 'ERROR',
              :url => server + '/#s=' + development_project.uri + '|analysisPage|head|' + "#{obj['report']['meta']['uri']}",
              :api => server + "/#{obj['report']['meta']['uri']}",
              :title => report['title'],
              :description => 'Report not tagged as preview.'
          })
        end
      end
    end
  end
end


$result.push({:section => 'Reports contains preview metric, not tagged as Preview', :OK => development_project.metrics.count - counter_error, :INFO => 0, :ERROR => counter_error, :output => output})

# reset output variables
counter_error = 0
output = []


metrics.each do |metric|

  # check included and excluded tags
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?

      # get folder part of the metric metadata
      folders = metric.content['folders']

      # check for the correct folder or if folder is not set print the metric
      if folders.nil?
        output.push(details = {
            :type => 'ERROR',
            :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
            :api => server + metric.uri,
            :title => metric.title,
            :description => 'Metric is not in folder.'
        })
        counter_error += 1
      else
        object = GoodData::get(folders[0]) #TODO first
        unless object['folder']['meta']['title'].include? 'ZOOM Preview'
          output.push(details = {
              :type => 'ERROR',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
              :api => server + metric.uri,
              :title => metric.title,
              :description => 'Metric is not in Zoom Preview folder.'
          })
          counter_error += 1
        end
      end
    end
  end
end

$result.push({:section => 'Metric is not in specific Zoom Preview folder or in any folder.', :OK => development_project.metrics.count - counter_error, :INFO => 0, :ERROR => counter_error, :output => output})

# reset output variables
counter_error = 0
output = []

# get all reports for given tag
reports = development_project.reports.select { |report| report.tag_set.include?(tag) }.sort_by(&:title)

reports.each do |report|

  # check included and excluded tags
  if tags_included.empty? || !(report.tag_set & tags_included).empty?
    if (report.tag_set & tags_excluded).empty?

      # get folder/domain part of the metadata
      folders = report.content['domains']

      # check if report is in preview folder/domain
      if (folders.to_s == '[]') || folders.nil?
        output.push(details = {
            :type => 'ERROR',
            :url => server + '/#s=' + development_project.uri + '|analysisPage|' + report.uri,
            :api => server + report.uri,
            :title => report.title,
            :description => 'Reports is not in any folder'
        })
        counter_error += 1
      else
        obj = GoodData::get(folders[0])
        unless obj['domain']['meta']['title'].include? 'ZOOM Preview'
          counter_error += 1
          output.push(details = {
              :type => 'ERROR',
              :url => server + '/#s=' + development_project.uri + '|analysisPage|' + report.uri,
              :api => server + report.uri,
              :title => report.title,
              :description => 'Reports is not in Zoom Preview folder'
          })
        end
      end
    end
  end
end

$result.push({:section => 'Reports not in specific Zoom Preview folder or in any folder.', :OK => development_project.reports.count - counter_error, :INFO => 0, :ERROR => counter_error, :output => output})

# reset output variables
counter_error = 0
output = []

reports.each do |report|

  # check included and excluded tags
  if tags_included.empty? || !(report.tag_set & tags_included).empty?
    if (report.tag_set & tags_excluded).empty?

      # get all objects that use report
      using_reports = report.usedby

      # select only dashboards from objects that used report
      using_reports.select { |dashboard| dashboard['category'] == 'projectDashboard' }.each do |dashboard|

        # get only report objects and extract tags
        object = GoodData::get(dashboard['link'])

        # check whether reports include preview tag
        unless object['projectDashboard']['meta']['title'].include? 'Zoom preview'
          output.push(details = {
              :type => 'ERROR',
              :url => server + '/#s=' + development_project.uri + '|analysisPage|' + report.uri,
              :api => server + report.uri,
              :title => report.title,
              :description => 'Reports is not on Preview dashboard'
          })
          counter_error += 1
        end
      end
    end
  end
end

$result.push({:section => 'Reports tagged Preview not in Preview dashboard', :OK => development_project.reports.count - counter_error, :INFO => 0, :ERROR => counter_error, :output => output})

# reset output variables
counter_error = 0
output = []

development_project.variables.each do |variable|

  # check included and excluded tags
  if tags_included.empty? || !(variable.tag_set & tags_included).empty?
    if (variable.tag_set & tags_excluded).empty?

      # continue with variable tags check
      if variable.title.include? name_starting
        unless variable.tags.include? tag

          output.push(details = {
              :type => 'ERROR',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + variable.uri,
              :api => server + variable.uri,
              :title => variable.title,
              :description => 'The variable is missing the "preview" as a tag.'
          })
          counter_error += 1
        end
      end
      if variable.tags.include? tag
        unless variable.title.include? name_starting
          output.push(details = {
              :type => 'ERROR',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + variable.uri,
              :api => server + variable.uri,
              :title => variable.title,
              :description => 'The variable with the "preview" as a tag is missing " ZOOM Preview - " in the title.'
          })
          counter_error += 1
        end
      end
    end
  end
end

$result.push({:section => 'Variable tags and titles errors', :OK => 0, :INFO => 0, :ERROR => counter_error, :output => output})

# TODO add analyticaldashboard in future, but it's not supported by GoodData now.

# reset output variables
counter_error = 0
output = []

# check metrics that depend on variables tagged 'preview' but are not preview
development_project.variables.each do |variable|

  # check included and excluded tags
  if tags_included.empty? || !(variable.tag_set & tags_included).empty?
    if (variable.tag_set & tags_excluded).empty?

      if variable.tag_set.include?(tag)
        variables = variable.usedby
        variables.select { |v| v['category'] == 'metric' }.each do |metric|

          metric = GoodData::MdObject[metric['link']]
          unless metric.tag_set.include?(tag)
            output.push(details = {
                :type => 'ERROR',
                :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
                :api => server + metric.uri,
                :title => metric.title,
                :description => 'The metric is using " preview " variables, but is not tagged.'
            })
            counter_error += 1
          end
        end
      end
    end
  end
end

$result.push({:section => 'Not tagged metrics using "preview" variables.', :OK => 0, :INFO => 0, :ERROR => counter_error, :output => output})

# reset output variables
counter_ok = 0
counter_error = 0
output = []

# check metrics and reports that are in folder starting with 'ZOOM Preview - ' are also tagged 'preview'
# prepare all folders for metrics first
all_folders={}
client.get("#{development_project.md['query']}/folders")['query']['entries'].map do |i|
  all_folders.[]=(i['title'], i['link'])
end
all_folders.values.uniq

# check all metrics
development_project.metrics.peach do |metric|
  if metric.content['folders'].to_s != ''
    if all_folders.key(metric.content['folders'].first.to_s).to_s.include?(name_starting)
      if !metric.tag_set.include?(tag)
        output.push(details = {
            :type => 'ERROR',
            :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
            :api => server + metric.uri,
            :title => metric.title,
            :description => 'The metric from preview folder is not tagged by the preview tag.'
        })
        counter_error += 1
      else
        output.push(details = {
            :type => 'OK',
            :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
            :api => server + metric.uri,
            :title => metric.title,
            :description => 'The metric from preview folder is already tagged by the preview tag.'
        })
        counter_ok += 1
      end
    end
  end
end

$result.push({:section => 'Metrics from preview folders have been checked for the preview tag.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})

# reset output variables
counter_ok = 0
counter_error = 0
output = []

# prepare all folders for reports first because the folders are different
all_folders={}
client.get("#{development_project.md['query']}/folders")['query']['entries'].map do |folder|
  all_folders.[]=(folder['title'], folder['link'])
end
all_folders.values.uniq

#check all reports
development_project.reports.peach do |report|
  if report.content['domains'].to_s != ''
    if all_folders.key(rep.content['domains'].first.to_s).to_s.include?(name_starting)
      if !report.tag_set.include?(tag)

        output.push(details = {
            :type => 'ERROR',
            :url => server + '/#s=' + development_project.uri + '|analysisPage|head|' + report.uri,
            :api => server + report.uri,
            :title => report.title,
            :description => 'The report from preview folder is not tagged by the preview tag.'
        })
        counter_error += 1
      else
        output.push(details = {
            :type => 'OK',
            :url => server + '/#s=' + development_project.uri + '|analysisPage|head|' + report.uri,
            :api => server + report.uri,
            :title => report.title,
            :description => 'The report from preview folder is alredy tagged by the preview tag.'
        })
        counter_ok += 1
      end
    end
  end
end

$result.push({:section => 'Reports from preview folders have been checked for the preview tag.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})

#reset output variables
counter_ok = 0
counter_error = 0
output = []

# check if metric depend on not preview variable
development_project.metrics.each do |metric|

  error = 0

  # check included and excluded tags
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?

      if metric.tag_set.include?(tag)
        objects = metric.using

        objects.select { |object| object['category'] == 'attribute' }.each do |object|
          object = development_project.attributes(object['link'])
          unless object.tags.to_s.split(' ').include?(tag)
            error = 1
          end
        end

        if error == 1
          output.push(details = {
              :type => 'ERROR',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
              :api => server + metric.uri,
              :title => metric.title,
              :description => 'The metric depends on not preview variable'
          })
          counter_error += 1
        else
          output.push(details = {
              :type => 'OK',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
              :api => server + metric.uri,
              :title => metric.title,
              :description => 'The metric does not depend on not preview variable'
          })
          counter_ok += 1
        end
      end
    end
  end
end

$result.push({:section => 'Check if metric depends on not preview variable.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
