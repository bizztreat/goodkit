require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]

# variables for standard output
counter_ok = 0
counter_error = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

development_project.dashboards.peach do |dashboard|

  if dashboard.author.full_name == 'ZOOM Performance Analytics'
    counter_ok += 1
  else
    output.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|projectDashboardPage|' + dashboard.uri,
        :api => server + dashboard.uri,
        :title => dashboard.title,
        :description => 'The author is not ZOOM Performance Analytics'
    })
    counter_error += 1
  end
end

development_project.reports.peach do |report|

  if report.author.full_name == 'ZOOM Performance Analytics'
    counter_ok += 1
  else
    output.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|objectPage|' + report.uri,
        :api => server + report.uri,
        :title => report.title,
        :description => 'The author is not ZOOM Performance Analytics'
    })
    counter_error += 1
  end
end

development_project.metrics.peach do |metric|

  if metric.author.full_name == 'ZOOM Performance Analytics'
    counter_ok += 1
  else
    output.push(error_details = {
        :type => 'ERROR',
        :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + metric.uri,
        :api => server + metric.uri,
        :title => metric.title,
        :description => 'The author is not ZOOM Performance Analytics'
    })
    counter_error += 1
  end
end

development_project.attributes.peach do |attribute|

  if attribute.author.full_name == 'ZOOM Performance Analytics'
    counter_ok += 1
  else
    output.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|objectPage|' + attribute.uri,
        :api => server + attribute.uri,
        :title => attribute.title,
        :description => 'The author is not ZOOM Performance Analytics'
    })
    counter_error += 1
  end
end

development_project.facts.peach do |fact|

  if fact.author.full_name == 'ZOOM Performance Analytics'
    counter_ok += 1
  else
    output.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|objectPage|' + fact.uri,
        :api => server + fact.uri,
        :title => fact.title,
        :description => 'The author is not ZOOM Performance Analytics'
    })
    counter_error += 1
  end
end

development_project.variables.peach do |variable|

  if variable.author.full_name == 'ZOOM Performance Analytics'
    counter_ok += 1
  else
    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|objectPage|' + variable.uri,
        :api => server + variable.uri,
        :title => variable.title,
        :description => 'The author is not ZOOM Performance Analytics'
    })
    counter_error += 1
  end
end

# TODO add analyticaldashboard in future, but it's not supported by GoodData now.

$result.push({:section => 'Check objects which are not created or modified by user ZOOM Performance Analytics.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect