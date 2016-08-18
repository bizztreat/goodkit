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
  opts.on('-r', '--remove REMOVE', 'Tags to remove') { |v| options[:tags_to_remove] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')
tags_to_remove = options[:tags_to_remove].to_s.split(',')

# variables for standard output
counter_info_metrics = 0
counter_info_reports = 0
counter_info_attributes = 0
counter_info_facts = 0
output_metrics = []
output_reports = []
output_attributes = []
output_facts = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# do metrics
development_project.metrics.peach do |metric|
  # check included and excluded tags
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?
      # check all tags to remove
      tags_to_remove.each do |tag|
      if (metric.tag_set.include? tag)
        #remove tag
        metric.remove_tag(tag)
        metric.save
        #print the result
        output_metrics.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
        :api => server + metric.uri,
        :title => metric.title,
        :description => 'The tag "' + tag + '" has been deleted from the metric.'
        })
        counter_info_metrics += 1
      end
    end
    end
  end
end
#push the results
$result.push({:section => 'Deleted tags from metrics.', :OK => 0, :INFO => counter_info_metrics, :ERROR => 0, :output => output_metrics})


#do reports
development_project.reports.peach do |report|
  # check included and excluded tags
  if tags_included.empty? || !(report.tag_set & tags_included).empty?
    if (report.tag_set & tags_excluded).empty?
      # check all tags to remove
      tags_to_remove.each do |tag|
      #remove tag
      if (report.tag_set.include? tag)
        report.remove_tag(tag)
        report.save
        #print the result
        output_reports.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|analysisPage|head|' + report.uri,
        :api => server + report.uri,
        :title => report.title,
        :description => 'The tag "' + tag + '" has been deleted from the report.'
        })
        counter_info_reports += 1
      end
    end
    end
  end
end
#push the results
$result.push({:section => 'Deleted tags from reports.', :OK => 0, :INFO => counter_info_reports, :ERROR => 0, :output => output_reports})


#do attributes
development_project.attributes.peach do |attribute|
  # check included and excluded tags
  if tags_included.empty? || !(attribute.tag_set & tags_included).empty?
    if (attribute.tag_set & tags_excluded).empty?
      # check all tags to remove
      tags_to_remove.each do |tag|
      #remove tag
      if (attribute.tag_set.include? tag)
        attribute.remove_tag(tag)
        attribute.save
        #print the result
        output_attributes.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|objectPage|' + attribute.uri,
        :api => server + attribute.uri,
        :title => attribute.title,
        :description => 'The tag "' + tag + '" has been deleted from the attribute.'
        })
        counter_info_attributes += 1
      end
    end
    end
  end
end
#push the results
$result.push({:section => 'Deleted tags from attributes.', :OK => 0, :INFO => counter_info_attributes, :ERROR => 0, :output => output_attributes})


#do facts
development_project.facts.peach do |fact|
  # check included and excluded tags
  if tags_included.empty? || !(fact.tag_set & tags_included).empty?
    if (fact.tag_set & tags_excluded).empty?
      # check all tags to remove
      tags_to_remove.each do |tag|
      #remove tag
      if (fact.tag_set.include? tag)
        fact.remove_tag(tag)
        fact.save
        #print the result
        output_facts.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|objectPage|' + fact.uri,
        :api => server + fact.uri,
        :title => fact.title,
        :description => 'The tag "' + tag + '" has been deleted from the fact.'
        })
        counter_info_facts += 1
      end
    end
    end
  end
end
#push the results
$result.push({:section => 'Deleted tags from facts.', :OK => 0, :INFO => counter_info_facts, :ERROR => 0, :output => output_facts})

# result as json_file
puts $result.to_json

client.disconnect
