require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

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
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# variables for standard output
counter_ok = 0
counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|

  GoodData.with_project(development_project) do |project|

    # for each dashboard and tab check for the URL including GA tracking code
    project.dashboards.each do |dashboard|
      dashboard.tabs.each do |tab|

        # check the GA tracking code
        if tab.items.to_s.include? 'https://demo.zoomint.com/stat/%CURRENT_DASHBOARD_URI%/%CURRENT_DASHBOARD_TAB_URI%'
          counter_ok += 1
        else
          counter_err += 1
          err_array.push(error_details = {
              :type => 'ERROR',
              :url => server + '/#s=/gdc/projects/' + development_project + '|projectDashboardPage|' + dashboard.uri + '|' + tab.identifier,
              :api => server + dashboard.uri,
              :title => dashboard.title + ' - ' + tab.title,
              :description => 'GA script is missing.'
          })
        end
      end
    end

    $result.push({:section => 'Missing GA code check.', :OK => counter_ok, :ERROR => counter_err, :output => err_array})

    puts $result.to_json

  end
end

GoodData.disconnect
