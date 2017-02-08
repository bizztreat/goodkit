require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_excluded] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

counter_ok = 0
counter_error = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# select original reports include and exclude tags
reports = development_project.reports.select { |report| (tags_included.empty? || !(report.tag_set & tags_included).empty?) && (report.tag_set & tags_excluded).empty? }

reports.peach do |report|
  begin
    counter_ok += 1
    report.definition.execute
  rescue
    counter_error += 1
    output.push(detail = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + report.uri,
        :api => server + report.uri,
        :title => report.title,
        :description => 'This report is not computable.'
    })
  end
end

$result.push({:section => 'Uncomputable reports', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
