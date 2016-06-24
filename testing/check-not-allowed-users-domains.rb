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
  opts.on('-d', '--project ID', 'Project') { |v| options[:project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-a', '--domains DOMAINS', 'Allowed Domains') { |v| options[:allowed_domains] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
project = options[:project]
server = options[:server]
allowed_domains = options[:allowed_domains].to_s.split(',')

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# variables for standard output
counter_info = 0
counter_error = 0
output = []
$result = []
domains_of_support = %w(gooddata.com clients.keboola.com)
allowed_domains += domains_of_support

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
project = client.projects(project)

project.users.each do |user|

  user_email_domain = user.email.split('@')[1]
  unless allowed_domains.include? user_email_domain
    counter_error += 1
    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + project.uri + '|projectPage|',
        :api => '',
        :title => user.first_name + ' ' + user.last_name,
        :description => user.email + ' email is not allow'
    })
  end

  if domains_of_support.include? user_email_domain
    counter_info += 1
    output.push(details = {
        :type => 'INFO',
        :url => server + '#s=' + project.uri + '|projectPage|',
        :api => '',
        :title => user.first_name + ' ' + user.last_name,
        :description => user.email + ' email is on support domain list'
    })
  end
end

$result.push({:section => 'Not allowed domains', :OK => 0, :INFO => counter_info, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect



