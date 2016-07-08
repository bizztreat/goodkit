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

# variables for script results
output = []
$result = []
counter_ok = 0
counter_error = 0

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

development_project.dashboards.each do |dashboard|

  # check included and excluded tags
  if tags_included.empty? || !(dashboard.tag_set & tags_included).empty?
    if (dashboard.tag_set & tags_excluded).empty?

      errors = []

      unless dashboard.locked?
        errors.push('UNLOCKED')
      end

      if dashboard.summary == ''
        errors.push('MISSING DESCRIPTION')
      end

      if dashboard.meta['unlisted'] == 1
        errors.push('MISSING DESCRIPTION')
      end

      if errors.empty?
        counter_ok += 1
      else
        output.push(details = {
            :type => 'ERROR',
            :url => server + '#s=' + development_project.uri + '|projectDashboardPage|' + dashboard.uri,
            :api => server + dashboard.uri,
            :title => dashboard.title,
            :description => 'The dashboard "' + dashboard.title + '" errors ' + errors.join(', ')
        })
        counter_error += 1
      end
    end
  end
end

$result.push({:section => 'Unfinished dashboards.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})

# reset result variables
output = []
counter_ok = 0
counter_error = 0

development_project.reports.each do |report|

  # check included and excluded tags
  if tags_included.empty? || !(report.tag_set & tags_included).empty?
    if (report.tag_set & tags_excluded).empty?

      errors = []

      unless report.locked?
        errors.push('UNLOCKED')
      end

      if report.summary == ''
        errors.push('MISSING DESCRIPTION')
      end

      if report.meta['unlisted'] == 1
        errors.push('MISSING DESCRIPTION')
      end

      if errors.empty?
        counter_ok += 1
      else
        output.push(details = {
            :type => 'ERROR',
            :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + report.uri,
            :api => server + report.uri,
            :title => report.title,
            :description => 'The report "'+ report.title + '" errors ' + errors.join(', ')
        })
        counter_error += 1
      end
    end
  end
end

$result.push({:section => 'Unfinished reports.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})

#reset result variables
output = []
counter_ok = 0
counter_error = 0

development_project.metrics.each do |metric|

  # check included and excluded tags
  if tags_included.empty? || !(metric.tag_set & tags_included).empty?
    if (metric.tag_set & tags_excluded).empty?

      errors = []

      unless metric.locked?
        errors.push('UNLOCKED')
      end

      if metric.summary == ''
        errors.push('MISSING DESCRIPTION')
      end

      if metric.meta['unlisted'] == 1
        errors.push('MISSING DESCRIPTION')
      end

      if errors.empty?
        counter_ok += 1
      else
        output.push(details = {
            :type => 'ERROR',
            :url => server + '#s=' + development_project.uri + '|objectPage|' + metric.uri,
            :api => server + metric.uri,
            :title => metric.title,
            :description => 'The metric "'+ metric.title + '" errors ' + errors.join(', ')
        })
        counter_error += 1
      end
    end
  end
end

$result.push({:section => 'Unfinished metrics.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
