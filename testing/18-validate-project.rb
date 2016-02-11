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
  opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]
start = options[:start]
server = options[:server]

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end

GoodData.with_connection(login: username, password: password, server: server) do |client|
  GoodData.with_project(start) do |project|
    puts project.validate().to_json
  end
end

GoodData.disconnect

