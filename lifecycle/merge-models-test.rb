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
    opts.on('-d', '--develproject NAME', 'Devel Project') { |v| options[:master] = v }
    opts.on('-s', '--startproject NAME', 'Devel Project') { |v| options[:child] = v }
    opts.on('-f', '--file FILE', 'Projects file') { |v| options[:file] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!


# assign credentials for script from user input and master project id
username = options[:username]
password = options[:password]
master = options[:master]
child = options[:child]
server = options[:server]

# variables for script results
result_array = []
$result = []

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|
    GoodData.with_project(master) do |master|
        
        # get master project blueprint (model)
        master_model = master.blueprint
                
            GoodData.with_project(child) do |child|

            customer_model = child.blueprint
            
            begin
                new_model = customer_model.merge(master_model).to_s
                
                rescue Exception => msg
                
                result_array.push(error_details = {
                               :type => "ERROR",
                               :url => "Merging two models is not possible." ,
                               :api => "Merging two models is not possible.",
                               :message => msg.to_s
                               })
                $result.push({:section => 'Merging two models is not possible.', :OK => 0, :ERROR => 1, :output => result_array})

                
                else
                result_array.push(error_details = {
                               :type => "INFO",
                               :url => "Models have been merged successfully" ,
                               :api => "Models have been merged successfully",
                               :message => "Models have been merged successfully"
                               })
                $result.push({:section => 'Models have been merged successfully', :OK => 1, :ERROR => 0, :output => result_array})

            end
        
        end
    end
end

#print out the result
puts $result.to_json

GoodData.disconnect
