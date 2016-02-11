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
  opts.on('-o', '--originalproject ID', 'Original Project') { |v| options[:original] = v }
  opts.on('-c', '--cloneproject NAME', 'Clone Project') { |v| options[:clone] = v }
  opts.on('-t', '--authtoken TOKEN', 'Authorization Token') { |v| options[:token] = v }
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
  project = client.projects(options[:original])
  cloned_project = project.clone(
      :title => options[:clone],
      :with_data => true, #TODO ??
      :with_users => true,
      :auth_token => options[:token]
  )

  ERRORS = 0

  clone_details = {
      :type => 'OK',
      :project_id => cloned_project.obj_id
  }

  puts JSON.generate(clone_details)

end

GoodData.disconnect
