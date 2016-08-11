require 'gooddata'
require 'optparse'

# define options for script configuration
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

start_project_metrics.peach do |metric_start|
  development_project_metrics.peach do |metric_development|

    # do the metrics with the same title
    if metric_start.title == metric_development.title

      # check if the start metric is computable
      begin
        metric_start.execute
      rescue
        output.push(details = {
            :type => 'ERROR',
            :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + metric_start.uri,
            :api => server + metric_start.uri,
            :title => metric_start.title,
            :description => 'Start metric is uncomputable.'
        })
        counter_error += 1
      else

        # check if the development metric is computable
        begin
          metric_development.execute
        rescue
          counter_error += 1
          output.push(details = {
              :type => 'ERROR',
              :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + metric_development.uri,
              :api => server + metric_development.uri,
              :title => metric_development.title,
              :description => 'Development metric is uncomputable.'
          })
        else

          # compare start and development metric
          if metric_development.execute == metric_start.execute
            counter_ok += 1
          else
            output.push(details = {
                :type => 'ERROR',
                :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + metric_development.uri,
                :api => server + metric_development.uri,
                :title => metric_development.title,
                :description => 'Development metric result is different.'
            })
            counter_error += 1
          end
        end
      end
    end
  end
end

$result.push({:section => 'Metric results between Start and Devel projects.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
