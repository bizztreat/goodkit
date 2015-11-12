require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# initiate parameters for user input
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# check all parameters
username = options[:username]
password = options[:password]
start = options[:start]
devel = options[:devel]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

puts 'Connecting to GoodData...'
puts 'Checking for non-used facts and attributes...'

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|
    
    # prepare hashes and arrays for results
    $devel_metrics = Hash.new
    $start_metrics = Hash.new
    unused_attr = []
    unused_facts = []
    
    # connect to project context
    project = client.projects(devel)
    
    puts '--- Printing unused Attributes:'
    
    # for each attribute
    project.attributes.each do |attr|
        
        num_objects = 0
        objects = attr.usedby
        objects.select  {|attribute| attribute["category"] == 'metric'}.each { |r|
            # get only metric objects
            num_objects += 1
        }
        
        objects.select  {|attribute| attribute["category"] == 'report'}.each { |r|
            # get only report objects
            num_objects += 1
        }
        
        # print the result if there is ZERO objects using that are using the attribute
        if num_objects == 0
            then puts attr.title + '  -  ' + server + '/#s=/gdc/projects/' + devel + '|objectPage|' + attr.uri
            
        end
    end
    
    puts '---'
    puts '--- Printing unused Facts:'
    puts '---'
    
    # for each fact do the check
    project.facts.each do |fact|
        
        num_objects = 0
        objects = fact.usedby
        objects.select  {|fact| fact["category"] == 'metric'}.each { |r|
            # get only metric objects
            num_objects += 1
        }
        
        objects.select  {|fact| fact["category"] == 'report'}.each { |r|
            # get only report objects
            num_objects += 1
        }
        
        # print the result if there is ZERO objects using that are using the attribute
        if num_objects == 0
            then puts fact.title + '  -  ' + server + '/#s=/gdc/projects/' + devel + '|objectPage|' + fact.uri
            
        end
    end
    
    
end

puts 'Disconnecting...'
GoodData.disconnect
