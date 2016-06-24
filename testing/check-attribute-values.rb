require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'rubygems'
require 'json'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-a', '--attributes ATTRIBUTES', 'Attributes') { |v| options[:attributes] = v }
  opts.on('-g', '--generate GENERATE', 'Generate') { |v| options[:generate] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_excluded] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server]
attributes = options[:attributes].to_s.split(',')
generate = options[:generate]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')


if generate.to_s.empty?
  generate = 'false'
end

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# variables for standard output
counter_info = 0
counter_error = 0
output = []
hash_final = {}
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# generate JSON file first
if generate == 'true'
  development_project.attributes.each do |attribute|
    if tags_included.empty? || !(attribute.tag_set & tags_included).empty?
      if (attribute.tag_set & tags_excluded).empty?
        if attributes.include? attribute.title
          values = []
          attribute.values.each do |value|
            value.each do |h|
              h.each do |_, value|
                unless v.include? development_project.pid
                  values.push(v)
                end
              end
            end
          end

          # creating hash of results and merging output
          hash = {attribute.title => values}
          if hash_final == {}
            hash_final = hash
          else
            hash_final = hash_final.merge(hash)
          end
        end
      end
    end
  end

  #write attributes and their values to the JSON file
  File.open('attributes.json', 'w') do |file|
    file.write(hash_final.to_json)
  end
end

# read JSON file and check values
if generate == 'false'
  # parse JSON file
  attributes = JSON.parse(File.read('attributes.json'))
  #check attributes if they are in JSON file
  development_project.attributes.each do |attribute|
    if attributes.has_key?(attribute.title)
      # download attribute's values first
      values = []
      attribute.values.each do |value|
        value.each do |h|
          h.each do |_, value|
            unless v.include? development_project.pid
              values.push(v)
            end
          end
        end
      end

      # Array list of missing values
      missing = values - attributes[attribute.title]
      # Array list of extra values
      extra = attributes[attribute.title] - values
      #check if there is any inconsistency
      if missing.any? || extra.any?
        counter_error += 1
        output.push(details = {
            :type => 'ERROR',
            :url => server + '/#s=' + development_project.uri + '|objectPage|' + a.uri,
            :api => server + attribute.uri,
            :title => attribute.title,
            :description => 'The attribute "' + attribute.title + '" is missing these values "' + missing.to_s + '" and contains extra values "' + extra.to_s + '".'
        })
      else
        counter_info += 1
        output.push(details = {
            :type => 'INFO',
            :url => server + '/#s=' + development_project.uri + '|objectPage|' + a.uri,
            :api => server + attribute.uri,
            :title => attribute.title,
            :description => 'The attribute`s "' + attribute.title + '" values are identical.'
        })
      end
    end
  end

  $result.push({:section => 'Checking values of attributes results', :OK => 0, :INFO => counter_info, :ERROR => counter_error, :output => output})
  puts $result.to_json
end

client.disconnect
