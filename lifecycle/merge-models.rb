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
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-f', '--file FILE', 'Projects File') { |v| options[:file] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
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

  # connect to development GoodData project
  GoodData.with_project(development_project) do |development_project|

    # get development project blueprint (model)
    development_project_model = development_project.blueprint

    # for each customer/child project merge models
    target_projects.each do |project|
      counter_ok += 1

      GoodData.with_project(project) do |child|

        child_model = child.blueprint
        new_model = child_model.merge(development_project_model) #TODO delete ?
        child.update_from_blueprint(new_model) #TODO delete ?

        begin
          new_model = child_model.merge(development_project_model)
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