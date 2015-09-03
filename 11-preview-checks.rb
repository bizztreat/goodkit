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

# change the tags to check here
tag = 'preview'

puts 'Connecting to GoodData...'
puts 'Testing Report results between Start and Devel projects.'

GoodData.with_connection(username, password) do |client|
    
    
    start = client.projects(options[:start])
    #devel = client.projects(options[:devel])
    #start = client.projects('x1c6gsmxhr84usnhww03s6ecx3625279')
    #devel = client.projects('t3m4hv0v5vrysctjqax88t2q2346t6vd')
    
    # We assume that reports have unique name inside a project
    
        metrics = start.metrics.select {|m| m.tag_set.include?(tag)}.sort_by(&:title)
        
        metrics.each do |met|

            puts met.title
            
            reports = met.usedby
            
            puts '--- --- --- --- '
            puts 'Reports that contains PREVIEW metrics and are not tagged PREVIEW:'
            #puts reports
            
            reports.select  {|report| report["category"] == 'report'}.each { |r|
                    # get only report objects and extract tags
                    obj = GoodData::get(r["link"])
                    
                    # check whether reports include preview tag
                    # puts obj['report']['meta']['title']
                    if obj['report']['meta']['tags'].include? "preview" then else
                        puts "https://secure.gooddata.com#{obj['report']['meta']['uri']}"
                    end
                }
            
            
            puts '--- --- --- --- '
            puts 'Metrics that are PREVIEW but not in specific folder:'
            folders = met.content["folders"]
            obj = GoodData::get(folders[0])
            
            #puts obj['folder']['meta']['title']
            if obj['folder']['meta']['title'].include? "ZOOM Preview" then else puts "https://secure.gooddata.com#{met.meta['uri']}" end
          
    end
    
end

puts 'Disconnecting...'
GoodData.disconnect
