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
  opts.on('-d', '--devel_project NAME', 'Devel Project') { |v| options[:devel_project] = v }
  opts.on('-s', '--start_project NAME', 'Devel Project') { |v| options[:start_project] = v }
  opts.on('-f', '--file FILE', 'Projects file') { |v| options[:file] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!


# assign credentials for script from user input and devel project project id
username = options[:username]
password = options[:password]
devel_project = options[:devel_project]
start_project = options[:start_project]
server = options[:server]

# variables for script results
result_array = []
$result = []

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|
  GoodData.with_project(devel_project) do |devel_project|

    # get devel project project blueprint (model)
    devel_project_model = devel_project.blueprint

    GoodData.with_project(start_project) do |start_project|

      start_project_model = start_project.blueprint

      begin
        new_model = start_project_model.merge(devel_project_model).to_s
      rescue Exception => message

        result_array.push(error_details = {
            :type => 'ERROR',
            :url => 'Merging two models is not possible.',
            :api => 'Merging two models is not possible.',
            :message => message.to_s
        })

        $result.push({:section => 'Merging two models is not possible.', :OK => 0, :ERROR => 1, :output => result_array})
      else
        result_array.push(error_details = {
            :type => 'INFO',
            :url => 'Models have been merged successfully',
            :api => 'Models have been merged successfully',
            :message => 'Models have been merged successfully'
        })

        $result.push({:section => 'Models have been merged successfully', :OK => 1, :ERROR => 0, :output => result_array})
      end
    end
  end
end

#print out the result
puts $result.to_json

GoodData.disconnect
