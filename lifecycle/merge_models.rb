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
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# assign credentials for script from user input and master project id
username = options[:username]
password = options[:password]
master = options[:master]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# variables for standard output
counter_ok = 0
counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# read all project ids we will be pushing changes to
csv = CSV.read(options[:file], :headers => true)
target_projects = csv['project-id']

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|
    GoodData.with_project(master) do |master|
        
        # get master project blueprint (model)
        master_model = master.blueprint
        
        # for each customer project merge models
        target_projects.each do |project|
            counter_ok += 1

            GoodData.with_project(project) do |child|

            customer_model = child.blueprint
            new_model = customer_model.merge(master_model)
            
            child.update_from_blueprint(new_model)
            
            begin
                new_model = customer_model.merge(master_model)
                
                rescue Exception => msg
                
                counter_err += 1
                err_array.push(error_details = {
                    :type => "ERROR",
                    :detail => msg.to_s,
                    :message => "Merging two models is not possible."
                })
                
                else
                
                child.update_from_blueprint(new_model)
            end
            
         end
      end
    end
    
    # prepare part of the results
    $result.push({:section => 'Merging models', :OK => counter_ok, :ERROR => counter_err, :output => err_array})
    
    puts $result.to_json

end

GoodData.disconnect