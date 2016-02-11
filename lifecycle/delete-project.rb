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
  opts.on('-d', '--deleteproject ID', 'Delete Project') { |v| options[:delete] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials from input parameters
username = options[:username]
password = options[:password]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|
  # get the project context using Project ID from user input
  project = client.projects(options[:delete])
  project.delete

  ERRORS = 0

  delete_details = {
      :type => 'OK'
  }

  puts JSON.generate(delete_details)

end

GoodData.disconnect
