# The script checks if the percentage based metric is computable first and then if the metric's result is in the right range.
require 'gooddata'
require 'optparse'

options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_excluded] = v }
  opts.on('-t', '--title TITLE', 'Title containes') { |v| options[:title] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')
special_tags = options[:title].to_s.empty? ? "%,Percentage,Ratio".to_s.split(',') : options[:title].to_s.split(',')


# variables for script results
output = []
$result = []
counter_ok = 0
counter_error = 0

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development project
development_project = client.projects(development_project)

# select metrics include and exclude tags
development_project_metrics = development_project.metrics.select { |metric| (tags_included.empty? || !(metric.tag_set & tags_included).empty?) && (metric.tag_set & tags_excluded).empty? }.sort_by(&:title)

# iterate throught every metric
  development_project_metrics.peach do |metric|
    if special_tags.any? { |s| metric.title.include?(s) }
      then
      begin
      if  metric.execute >= 0 && metric.execute <= 100 then
        counter_ok += 1
      else
        counter_error += 1
        output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|objectPage|' + metric.uri,
        :api => server + metric.uri,
        :title => metric.title,
        :description => 'The result of the metric is out of the range.'
        })
      end
      rescue
        counter_error += 1
        output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|objectPage|' + metric.uri,
        :api => server + metric.uri,
        :title => metric.title,
        :description => 'The metric is uncomputable.'
        })
      end
end
  end

 $result.push({:section => 'Percentage based metrics check.', :OK => counter_ok, :ERROR => counter_error, :output =>  output})

# result as json_file
puts $result.to_json

GoodData.disconnect
