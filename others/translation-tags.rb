require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

def translation_tags(csv, language, object)

  tags = object.tags.split(' ')

  tags.each do |tag|

    row = csv.select { |row| row['en'] == tag }.first

    unless row.nil? || row[language].empty?

      object.remove_tag(tag)
      object.add_tag(row[language])
      object.save
    end
  end
end

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--project ID', 'Project') { |v| options[:project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-l', '--language Language', 'Language') { |v| options[:language] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
project = options[:project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
language = options[:language]

keys = %w(en cz)
csv = CSV.read('dictionaries/translation/tags-dictionary.csv').map { |row| Hash[keys.zip(row)] }

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
project = client.projects(project)

project.dashboards.each do |dashboard|
  translation_tags(csv, language, dashboard)
end

project.reports.each do |report|
  translation_tags(csv, language, report)
end

project.metrics.each do |metric|
  translation_tags(csv, language, metric)
end

project.attributes.each do |attribute|
  translation_tags(csv, language, attribute)
end

project.facts.each do |fact|
  translation_tags(csv, language, fact)
end

project.variables.each do |variable|
  translation_tags(csv, language, variable)
end

client.disconnect


