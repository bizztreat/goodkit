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
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }

end.parse!

# get parameters from the user input
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# connect to gooddata and check missing reports and metrics between projects
GoodData.with_connection(login: username, password: password, server: server) do |client|

  # get all reports, metrics, variables from devel project
  GoodData.with_project(devel) do |project|

    attribute = project.attributes('/gdc/md/zlrycmc434kh3t0b8b7s5n9effcqmuv2/obj/3092')
    #value = GoodData::Attribute.find_element_value('/gdc/md/zlrycmc434kh3t0b8b7s5n9effcqmuv2/obj/3092/elements?id=23169424', {client: client, project: project})
    #puts value.to_s

    #attribute = GoodData::Attribute['/gdc/md/zlrycmc434kh3t0b8b7s5n9effcqmuv2/obj/3092/', {:client => client, :project => project}]
    #value = GoodData::Attribute.find_element_value('/gdc/md/zlrycmc434kh3t0b8b7s5n9effcqmuv2/obj/3092/elements?id=', {client: client, project: project})
    #attribute = project.attributes('/gdc/md/zlrycmc434kh3t0b8b7s5n9effcqmuv2/obj/3092')
    #att = attribute.values_for('/gdc/md/zlrycmc434kh3t0b8b7s5n9effcqmuv2/obj/3092/elements?id=23169424')
    #puts 'a'
    #a = project.attributes('/gdc/md/zlrycmc434kh3t0b8b7s5n9effcqmuv2/obj/3092/elements?id=23169424')  #/elements?id=23169424
    #v = a.values_for('23169424')
  end
end

GoodData.disconnect
