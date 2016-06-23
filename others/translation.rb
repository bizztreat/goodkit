require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

#TODO co už tam není reportovat

def add_to_csv(csv, keys, object, url)

  unless csv.any? { |row| row['identifier'] == object.identifier }

    row = Hash[keys.map { |key| [key, ''] }]
    row['identifier'] = object.identifier

    if object.respond_to?(:category)
      row['category'] = '=HYPERLINK("' + url + '","' + object.category + '")'
    else
      row['category'] = '=HYPERLINK("' + url + '","tab")'
    end

    row['en_title'] = object.title

    if object.respond_to?(:summary)
      row['en_description'] = object.summary
    end

    csv.push(row)
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

keys = %w(identifier category en_title en_description cz_title cz_description)
csv = CSV.read('dictionaries/translation/dictionary.csv').map { |row| Hash[keys.zip(row)] }

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
project = client.projects(project)

project.dashboards.each do |dashboard|
  url = server + '/#s=' + project.uri + '|projectDashboardPage|' + dashboard.uri
  csv = add_to_csv(csv, keys, dashboard, url)
  dashboard.tabs.each do |tab|
    url = server + '/#s=' + project.uri + '|projectDashboardPage|' + dashboard.uri + '|' + tab.identifier
    csv = add_to_csv(csv, keys, tab, url)
  end
end

project.reports.each do |report|
  url = server + '#s=' + project.uri + '|analysisPage|head|' + report.uri
  csv = add_to_csv(csv, keys, report, url)
end

project.metrics.each do |metric|
  url = server + '/#s=' + project.uri + '|objectPage|' + metric.uri
  csv = add_to_csv(csv, keys, metric, url)
end

project.attributes.each do |attribute|
  url = server + '/#s=' + project.uri + '|objectPage|' + attribute.uri
  csv = add_to_csv(csv, keys, attribute, url)
end

project.facts.each do |fact|
  url = server + '/#s=' + project.uri + '|objectPage|' + fact.uri
  csv = add_to_csv(csv, keys, fact, url)
end

client.disconnect

# write hash to
CSV.open('dictionaries/translation/dictionary.csv', 'w') do |file|
  csv.each do |row|
    file << row.values
  end
end



