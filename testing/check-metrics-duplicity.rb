require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'levenshtein' #levenshtein-ffi

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-t', '--threshold Threshold', 'Levenshtein distance threshold') { |v| options[:levenshtein_distance_threshold] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_excluded] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
levenshtein_distance_threshold = options[:levenshtein_distance_threshold].to_i
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')


# variables for standard output
counter_error = 0
counter_info = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

development_project_metrics = []

development_project.metrics.each do |metric|
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?
      development_project_metrics.push({:uri => metric.uri, :title => metric.title, :pretty_expression => metric.pretty_expression})
    end
  end
end

# check metrics duplicity in project
while (development_project_metrics.length > 0)

  metric_1 = development_project_metrics.pop

  development_project_metrics.each do |metric_2|

    metric_1_pretty_expression_without_spaces = metric_1[:pretty_expression].split(' ').sort.join
    metric_2_pretty_expression_without_spaces = metric_2[:pretty_expression].split(' ').sort.join

    # skip if the metric contains just SELECT and a constant
    unless metric_2[:pretty_expression] =~ /^SELECT -?\d+(\.\d+)?$/

      pretty_expressions_distance = Levenshtein.distance(metric_1_pretty_expression_without_spaces, metric_2_pretty_expression_without_spaces)

      if pretty_expressions_distance <= levenshtein_distance_threshold
        if pretty_expressions_distance == 0
          output.push(details = {
              :distance => 0,
              :type => 'ERROR',
              :url => server + '#s=' + development_project.uri + '|objectPage|' + metric_2[:uri],
              :api => server + metric_1[:uri],
              :title => metric_1[:pretty_expression],
              :description => '<a href="' + server + '#s=' + development_project.uri + '|objectPage|' + metric_1[:uri] + '">Metric 1</a>, <a href="' + server + '#s=' + development_project.uri + '|objectPage|' + metric_2[:uri] + '">Metric 2</a>'
          })
          counter_error += 1
        else
          output.push(details = {
              :distance => pretty_expressions_distance,
              :type => 'INFO',
              :url => server + '#s=' + development_project.uri + '|objectPage|' + metric_2[:uri],
              :api => server + metric_1[:uri],
              :title => metric_1[:pretty_expression],
              :description => '<a href="' + server + '#s=' + development_project.uri + '|objectPage|' + metric_1[:uri] + '">Metric 1</a>, <a href="' + server + '#s=' + development_project.uri + '|objectPage|' + metric_2[:uri] + '">Metric 2</a>'
          })
          counter_info += 1
        end
      end
    end
  end
end

output.sort { |error_detail_1, error_detail_2| error_detail_1[:distance].to_i <=> error_detail_2[:distance].to_i }

$result.push({:section => 'Duplicity in Devel project', :OK => 0, :INFO => counter_info, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect


