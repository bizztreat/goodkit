require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'json'

# collect all parameters from user
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }

end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]

$result = []

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end

GoodData.with_connection(login: username, password: password, server: server) do |client|
  GoodData.with_project(devel) do |project|
    validation = project.validate().to_json

    #TODO count of errors
    $result.push({:section => 'Validate Project', :OK => 0, :ERROR => 0, :output => validation})

    puts $result.to_json
  end
end

GoodData.disconnect

