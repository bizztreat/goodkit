require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# set all options
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-m', '--masterproject NAME', 'Master Project') { |v| options[:master] = v }
    opts.on('-d', '--releasedate DATE', 'Release Date') { |v| options[:date] = v }
    opts.on('-f', '--file FILE', 'Projects file') { |v| options[:file] = v }
    
end.parse!

# assign credentials for script from user input and master project id
username = options[:username]
password = options[:password]
master = options[:master]

puts 'Connecting to GoodData...'

# read all project ids we will be pushing changes to
csv = CSV.read(options[:file], :headers => true)
target_projects = csv['project-id']

# connect to GoodData
GoodData.with_connection(username, password) do |client|
    GoodData.with_project(master) do |master|
        
        # get master project blueprint (model)
        master_model = master.blueprint
        
        # for each customer project merge models
        target_projects.each do |project|
            
            GoodData.with_project(project) do |child|

            customer_model = child.blueprint
            new_model = customer_model.merge(master_model)
            
            child.update_from_blueprint(new_model)
            
            end
        end
    end
end

GoodData.disconnect


puts 'Model changes have been applied'
puts 'Disconnecting...'
GoodData.disconnect
