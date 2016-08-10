# Two steps, first generate a json file with all names and then compare project with this file.
# There is a switch you use for changing behaviour of the script -g Generate "true" means the script generate the json file 
# from the project with all names
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'rubygems'
require 'json'

# prepare all parameters options
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }
  opts.on('-g', '--generate GENERATE', 'Generate') { |v| options[:generate] = v } # if generate true, then the script works as a json generator

end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
incl = options[:incl]
excl = options[:excl]
generate = options[:generate].to_s.empty? ? 'false' : options[:generate]

# make arrays from incl and excl parameters
if incl.to_s != ''
  incl = incl.split(",")
end

if excl.to_s != ''
  excl = excl.split(",")
end

counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

GoodData.with_connection(login: username, password: password, server: server) do |client|

  # get the devel project context
  devel = client.projects(devel)
  if generate == "true" then
    #attributes
    all_attributes = []
    client.get("#{devel.md['query']}/attributes")['query']['entries'].map do |i|
      all_attributes.push(i['title'])
    end
    hash = {:attributes => all_attributes}

    all_datasets = []
    client.get("#{devel.md['query']}/datasets")['query']['entries'].map do |i|
      all_datasets.push(i['title'])
    end
    hash2 = {:datasets => all_datasets}


    all_facts = []
    client.get("#{devel.md['query']}/facts")['query']['entries'].map do |i|
      all_facts.push(i['title'])
    end

    #$result.add( :facts  => [all_facts])
    hash3 = {:facts => all_facts}
    hash_final = hash.merge(hash2).merge(hash3)
    File.open("sety.json", "w") do |f|
      f.write(hash_final.to_json)
    end
  end
  # ----------------------------SECOND STEP--------------------
  if generate == "false" then
    # parse JSON file
    sety = JSON.parse(File.read('sety.json'))

    #Check attributes
    all_attributes = []
    client.get("#{devel.md['query']}/attributes")['query']['entries'].map do |i|
      all_attributes.push(i['title'])
    end
    json_attributes = sety['attributes']
    missing_project = json_attributes - all_attributes
    missing_project.each do |object|
      counter_err += 1
      err_array.push(error_details = {
          :type => "ERROR",
          :url => '',
          :api => '',
          :title => object,
          :description => "The attribute is missing in the project!"
      })
    end
    missing_json = all_attributes - json_attributes
    missing_json.each do |object|
      counter_err += 1
      err_array.push(error_details = {
          :type => "ERROR",
          :url => '',
          :api => '',
          :title => object,
          :description => "The attribute is extra in the project!"
      })
    end

    $result.push({:section => "Attributes errors.", :OK => 0, :ERROR => counter_err, :output => err_array})
    counter_err = 0
    err_array = []

    # Check datasets
    all_datasets = []
    client.get("#{devel.md['query']}/datasets")['query']['entries'].map do |i|
      all_datasets.push(i['title'])
    end
    json_datasets = sety['datasets']
    missing_project = json_datasets - all_datasets
    missing_project.each do |object|
      counter_err += 1
      err_array.push(error_details = {
          :type => "ERROR",
          :url => '',
          :api => '',
          :title => object,
          :description => "The dataset is missing in the project!"
      })
    end
    missing_json = all_datasets - json_datasets
    missing_json.each do |object|
      counter_err += 1
      err_array.push(error_details = {
          :type => "ERROR",
          :url => '',
          :api => '',
          :title => object,
          :description => "The dataset is extra in the project!"
      })
    end

    $result.push({:section => "Datasets errors.", :OK => 0, :ERROR => counter_err, :output => err_array})
    counter_err = 0
    err_array = []

    # Check facts
    all_facts = []
    client.get("#{devel.md['query']}/facts")['query']['entries'].map do |i|
      all_facts.push(i['title'])
    end
    json_facts = sety['facts']
    missing_project = json_facts - all_facts
    missing_project.each do |object|
      counter_err += 1
      err_array.push(error_details = {
          :type => "ERROR",
          :url => '',
          :api => '',
          :title => object,
          :description => "The fact is missing in the project!"
      })
    end
    missing_json = all_facts - json_facts
    missing_json.each do |object|
      counter_err += 1
      err_array.push(error_details = {
          :type => "ERROR",
          :url => '',
          :api => '',
          :title => object,
          :description => "The fact is extra in the project!"
      })
    end

    $result.push({:section => "Fact errors.", :OK => 0, :ERROR => counter_err, :output => err_array})

    puts $result.to_json
  end
end

GoodData.disconnect
