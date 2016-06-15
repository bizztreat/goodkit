require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--devel_project NAME', 'Devel Project') { |v| options[:devel_project] = v }
  opts.on('-f', '--file FILE', 'Projects File') { |v| options[:file] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# assign credentials for script from user input and master project id
username = options[:username]
password = options[:password]
devel_project = options[:devel_project]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

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
  GoodData.with_project(devel_project) do |devel_project|

    # get master project blueprint (model)
    devel_project_model = devel_project.blueprint

    # for each customer project merge models
    target_projects.each do |project|
      counter_ok += 1

      GoodData.with_project(project) do |child|

        child_model = child.blueprint
        new_model = child_model.merge(devel_project_model) #TODO delete ?
        child.update_from_blueprint(new_model) #TODO delete ?

        begin
          new_model = child_model.merge(devel_project_model)
        rescue Exception => message

          counter_err += 1
          err_array.push(error_details = {
              :type => 'ERROR',
              :detail => message.to_s,
              :message => 'Merging two models is not possible.'
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