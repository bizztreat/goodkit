require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    
end.parse!

#username = ''
#password = ''
username = options[:username]
password = options[:password]

start = options[:start]
devel = options[:devel]
#start = 'x1c6gsmxhr84usnhww03s6ecx3625279'
#devel = 'wjvvna1eukc92gechtxlm7blcv22gsow'

#testing master project ID = y672cuxov5x6swn64tlaz5jwcrez0wid

puts 'Connecting to GoodData...'
puts 'Checking for non-used facts and attributes...'

GoodData.with_connection(username, password) do |client|
    
    $devel_metrics = Hash.new
    $start_metrics = Hash.new
    unused_attr = []
    unused_facts = []
    
    project = client.projects(devel)
    
    puts '--- Printing unused Attributes:'
    
    project.attributes.each do |attr|
        
        num_objects = 0
        objects = attr.usedby
        objects.select  {|attribute| attribute["category"] == 'metric'}.each { |r|
            # get only report objects and extract tags
            num_objects += 1
        }
        
        objects.select  {|attribute| attribute["category"] == 'report'}.each { |r|
            # get only report objects and extract tags
            num_objects += 1
        }
        
        #puts objects
        if num_objects == 0
            then puts attr.title + '  -  ' + 'https://secure.gooddata.com/#s=/gdc/projects/' + devel + '|objectPage|' + attr.uri
            
        end
    end
    
    puts '---'
    puts '--- Printing unused Facts:'
    puts '---'
    
    project.facts.each do |fact|
        
        num_objects = 0
        objects = fact.usedby
        objects.select  {|fact| fact["category"] == 'metric'}.each { |r|
            # get only report objects and extract tags
            num_objects += 1
        }
        
        objects.select  {|fact| fact["category"] == 'report'}.each { |r|
            # get only report objects and extract tags
            num_objects += 1
        }
        
        #puts objects
        if num_objects == 0
            then puts fact.title + '  -  ' + 'https://secure.gooddata.com/#s=/gdc/projects/' + devel + '|objectPage|' + fact.uri
            
        end
    end
    
    
end

puts 'Disconnecting...'
GoodData.disconnect
