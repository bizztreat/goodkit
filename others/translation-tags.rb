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
  opts.on('-l', '--language Language', 'Language') { |v| options[:language] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
project = options[:project]
server = options[:server]
language = options[:language]

# turn off logging for clear output
GoodData.logging_off

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# variables for standard output
counter_ok = 0
counter_error = 0
output = []
$result = []

keys = %w(identifier category en_title en_description cz_title cz_description)
csv = CSV.read('dictionaries/translation/objects-objects-dictionary.csv').map { |row| Hash[keys.zip(row)] }

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
project = client.projects(project)

csv.peach do |row|

  if (row.key? language + '_title') && (row.key? language + '_description')

    if row['category'].include? '"tab"'
      catch :take_me_out do
        project.dashboards.each do |dashboard|
          dashboard.tabs.each do |tab|
            if tab.identifier == row['identifier']
              tab.title = row[language + '_title'].nil? ? tab.title : row[language + '_title'].to_s
              dashboard.save
              throw :take_me_out # break 2
            end
          end
        end
      end
    else
      object = project.objects(row['identifier'])
      object.title = row[language + '_title'].nil? ? object.title : row[language + '_title'].to_s
      object.summary = row[language + '_description'].nil? ? object.summary : row[language + '_description'].to_s
      object.save
    end
  else
    output.push(details = {
        :type => 'ERROR',
        :url => '#',
        :api => '#',
        :title => language,
        :description => 'The language is not supported'
    })
    break
  end
end

$result.push({:section => 'Translated objects', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect


