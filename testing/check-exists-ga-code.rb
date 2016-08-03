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

# for each dashboard and tab check for the URL including GA tracking code
development_project.dashboards.each do |dashboard|
  dashboard.tabs.each do |tab|

    # check the GA tracking code
    if tab.items.to_s.include? 'https://demo.zoomint.com/stat/%CURRENT_DASHBOARD_URI%/%CURRENT_DASHBOARD_TAB_URI%'
      counter_ok += 1
    else
      output.push(details = {
          :type => 'ERROR',
          :url => server + '/#s=' + development_project.uri + '|projectDashboardPage|' + dashboard.uri + '|' + tab.identifier,
          :api => server + dashboard.uri,
          :title => dashboard.title + ' - ' + tab.title,
          :description => 'GA script is missing.'
      })
      counter_error += 1
    end
  end
end

$result.push({:section => 'Missing GA code check.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
