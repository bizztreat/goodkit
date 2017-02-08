require 'gooddata'
require 'optparse'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]

# variables for standard output
counter_info = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

development_project.datasets.each do |dataset|

  if %w(CaseNotClosed Case).include? dataset.title

    dataset.facts.each do |fact|

      fact.usedby.each do |object|

        if object['category'] == 'report'
          output.push(details = {
              :type => 'INFO',
              :url => server + '/#s=' + development_project.uri + '|analysisPage|head|' + object['link'],
              :api => server + object['link'],
              :title => object['title'],
              :description => 'The fact "' + fact.title + '" is used in this report.'
          })
          counter_info += 1
          next
        end

        if object['category'] == 'metric'
          output.push(details = {
              :type => 'INFO',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + object['link'],
              :api => server + object['link'],
              :title => object['title'],
              :description => 'The fact "' + fact.title + '" is used in this metric.'
          })
          counter_info += 1
        end
      end
    end

    dataset.attributes.each do |attribute|

      attribute.usedby.each do |object|
        if object['category'] == 'report'
          output.push(details = {
              :type => 'INFO',
              :url => server + '/#s=' + development_project.uri + '|analysisPage|head|' + object['link'],
              :api => server + object['link'],
              :title => object['title'],
              :description => 'The attribute "' + attribute.title + '" is used in this report.'
          })
          counter_info += 1
          next
        end

        if object['category'] == 'metric'
          output.push(details = {
              :type => 'INFO',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + object['link'],
              :api => server + object['link'],
              :title => object['title'],
              :description => 'The attribute "' + attribute.title + '" is used in this metric.'
          })
          counter_info += 1
        end
      end
    end

    $result.push({:section => dataset.title + ' objects are used in', :OK => 0, :INFO => counter_info, :ERROR => 0, :output => output.sort_by { |row| row[:title] }})

    # reset output variables
    output = []
  end
end

$result.sort_by { |row| row[:section] }
puts $result.to_json

client.disconnect
