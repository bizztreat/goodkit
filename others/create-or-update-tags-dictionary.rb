require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

def add_to_csv(csv, keys, object)

  tags = object.tags.split(' ')

  tags.each do |tag|

    unless csv.any? { |row| row['en'] == tag }

      # tags which can't be translated
      unless (%w(demo qm gamification performance).include? tag) || (tag =~ /^-?\d+(\.\d+)?$/)

        row = Hash[keys.map { |key| [key, ''] }]
        row['en'] = tag
        csv.push(row)
      end
    end
  end

  csv
end

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--project ID', 'Project') { |v| options[:project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
project = options[:project]
server = options[:server]

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

keys = %w(en cz)
csv = CSV.read('dictionaries/translation/tags-dictionary.csv').map { |row| Hash[keys.zip(row)] }

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
project = client.projects(project)

project.dashboards.each do |dashboard|
  csv = add_to_csv(csv, keys, dashboard)
end

project.reports.each do |report|
  csv = add_to_csv(csv, keys, report)
end

project.metrics.each do |metric|
  csv = add_to_csv(csv, keys, metric)
end

project.attributes.each do |attribute|
  csv = add_to_csv(csv, keys, attribute)
end

project.facts.each do |fact|
  csv = add_to_csv(csv, keys, fact)
end

project.variables.each do |variable|
  csv = add_to_csv(csv, keys, variable)
end

client.disconnect

CSV.open('dictionaries/translation/tags-dictionary.csv', 'w') do |file|
  csv.each do |row|
    file << row.values
  end
end



