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

GoodData.logging_off

# assign credentials for script from user input and master project id
username = options[:username]
password = options[:password]
master = options[:master]
child = options[:child]
server = options[:server]


# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

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
                
                $error_details = {
                    :type => "ERROR",
                    :detail => msg.to_s,
                    :message => "Merging two models is not possible."
                }
                
                puts JSON.generate($error_details)
                
                else
                
                puts "Models have been merged successfully"
            end
        
        end
    end
end

GoodData.disconnect
