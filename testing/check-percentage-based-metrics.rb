require 'gooddata'
require 'optparse'

options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-t', '--title_illegal_substrings TITLE', 'Title illegal substrings') { |v| options[:title] = v }
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
title_illegal_substrings = options[:title_illegal_substrings].to_s.empty? ? '%,Percentage,Ratio'.to_s.split(',') : options[:title_illegal_substrings].to_s.split(',')

# variables for script results
output = []
$result = []
counter_ok = 0
counter_error = 0

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development project
development_project = client.projects(development_project)

development_project.metrics.peach do |metric|

  # check included and excluded tags
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?

      if title_illegal_substrings.any? { |title_illegal_substring| metric.title.include? title_illegal_substring }

        begin
          metric_result = metric.execute
          if metric_result >= 0 && metric_result <= 1
            counter_ok += 1
          else
            output.push(details = {
                :type => 'ERROR',
                :url => server + '#s=' + development_project.uri + '|objectPage|' + metric.uri,
                :api => server + metric.uri,
                :title => metric.title,
                :description => 'The result ' + metric_result + ' of the metric is out of the range.'
            })
            counter_error += 1
          end
        rescue
          output.push(details = {
              :type => 'ERROR',
              :url => server + '#s=' + development_project.uri + '|objectPage|' + metric.uri,
              :api => server + metric.uri,
              :title => metric.title,
              :description => 'The metric is uncomputable.'
          })
          counter_error += 1
        end
      end
    end
  end
end

$result.push({:section => 'Percentage based metrics check.', :OK => counter_ok, :ERROR => counter_error, :output => output})
puts $result.to_json
client.disconnect
