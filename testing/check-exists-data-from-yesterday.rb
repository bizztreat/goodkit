require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-a', '--attribute ATTRIBUTE', 'Attribute') { |v| options[:attribute] = v } # uri of some attribute like an ID (Orders) in this format: /gdc/md/projectspid/obj/1664
  opts.on('-t', '--time TIME', 'Time') { |v| options[:time] = v } # must to be filled by with attribute from time dimension 'Month/Year (your time dimension)'

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
attribute = options[:attribute]
time = options[:time]

counter_info = 0
counter_error = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

metric = project.add_measure 'SELECT COUNT(['+ attribute +']) WHERE ['+ time +'] = PREVIOUS', title: 'Test the data'
metric.save

begin
  if metric.execute.to_s == ''
    output.push(error_details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
        :api => server + metric.uri,
        :title => project.title,
        :description => 'There are no data from yesterday.'
    })
    counter_error += 1
  else
    output.push(error_details = {
        :type => 'INFO',
        :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
        :api => server + metric.uri,
        :title => project.title,
        :description => 'There are some data from yesterday.'
    })
    counter_info += 1
  end
rescue
  output.push(error_details = {
      :type => 'ERROR',
      :url => server + '/#s=' + development_project.uri + '|objectPage|' + metric.uri,
      :api => server + metric.uri,
      :title => project.title,
      :description => 'There is problem with the metric. It is uncomputable.'
  })
  counter_error += 1
end

metric.delete
$result.push({:section => 'The result if there are some data from yesterday.', :OK => 0, :INFO => counter_info, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
