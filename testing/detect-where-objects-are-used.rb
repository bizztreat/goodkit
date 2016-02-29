#Detect where individual attributes or facts are used
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
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
    # change the behaviour of script - choose "a" for attributes or "f" for facts to detect where these objects are being used
    opts.on('-o', '--object OBJECT', 'Object') { |v| options[:object] = v }

end.parse!

# check all parameters
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]
object = options[:object]


# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

result_array = []
$result = []
num_objects = 0


# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|

    # connect to project context
    project = client.projects(devel)

    #switcher for object type
     case object
     #------------ Attributes------------
     when 'a'
   # Find for each attribute its usage
   project.attributes.each do |attr|
     
      project.reports.peach do |report|

        if report.definition.using?(attr)
        
        then
          #push error detail to result array
          result_array.push(error_details = {
                               :type => "INFO",
                               :url => server + '/#s=/gdc/projects/' + devel + '|analysisPage|head|' + report.uri ,
                               :api => server + report.uri,
                               :message => 'The attribute (' + attr.title + ') is being used in report (' + report.title + ').'
                               })
            # count objects
            num_objects += 1

        else
        end
      end
    #save info in the result variable
    $result.push({:section => 'The attribute "' + attr.title + '" (' + server + '/#s=/gdc/projects/' + devel + '|objectPage|' + attr.uri + ') report usage.', :OK => num_objects, :ERROR => 0, :output => result_array})          
    result_array = []
    num_objects=0
   end
 #------------ Facts ------------
   when 'f'  
     # Find for each attribute its usage
   project.facts.each do |fact|
      project.reports.peach do |report|
        if report.definition.using?(fact)      
        then
          #push error detail to result array
          result_array.push(error_details = {
                               :type => "INFO",
                               :url => server + '/#s=/gdc/projects/' + devel + '|analysisPage|head|' + report.uri ,
                               :api => server + report.uri,
                               :message => 'The fact "' + fact.title + '" is being used in report "' + report.title + '".'
                               })
            # count objects
            num_objects += 1
            
        else
        end
      end
    #save info in the result variable
    $result.push({:section => 'The fact "' + fact.title + '" (' + server + '/#s=/gdc/projects/' + devel + '|objectPage|' + fact.uri + ') report usage.', :OK => num_objects, :ERROR => 0, :output => result_array})
    result_array = []
    num_objects=0          
end 
 
else
  puts "ERROR: Wrong object parameter. Please choose 'a' for attributes or 'f' for facts"
end

end

#print out the result
$result.to_json

GoodData.disconnect
