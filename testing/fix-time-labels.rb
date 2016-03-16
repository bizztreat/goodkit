#Fix time attributes - move to "Date and Time" folder
# and delete characters from name of the attribute when the parameter "remove" is set to value "true"
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# Method for creating a folder
def create_folder(project, title, description = "")
  res = project.client.post(project.md['obj'], {"dimension":
  {"meta":
    {"title":title,"summary":description,"tags":"","deprecated":0},"content":{"attributes":[]}}})
  project.objects(res['uri'])
end


options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-r', '--hostname REMOVE', 'Remove characters') { |v| options[:remove] = v }
  opts.on('-c', '--hostname CHARS', 'Characters to remove') { |v| options[:chars] = v }

end.parse!

# get all parameters - username, password and project id
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]
delete_chars = options[:remove]
chars_to_delete = options[:chars]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end


# variables for standard output
counter_ok = 0
counter_err = 0
counter_names_ok = 0
counter_names_err = 0
result_array = []
result_names_array = []
$result = []
folder_done = false

# turn off logging for clear output or ---> GoodData.logging_http_on
GoodData.logging_off
#GoodData.logging_http_on

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|

# connect to project
  GoodData.with_project(devel) do |project|
  # -----------ATTRIBUTES----------------
  # Let's cache all the folders containing attributes to speed things up
   folder_uris = project.attributes.map { |a| a.content['dimension'] }.uniq.compact

   folder_cache = folder_uris.reduce({}) { |a, e| a[e] = project.objects(e); a }
  # Let's cache all the folders in project to check if "Date and Time" folder already exist and get it´s uri later
   all_folders={}
   client.get("#{project.md['query']}/dimensions")['query']['entries'].map do |i|
          all_folders.[]=(i['title'],i['link'])
      end
   all_folders.values.uniq

  # Let's start to check attributes
    project.attributes.each do |a|

     if a.identifier.include? "attr.time"
     then
     #change replace the string in name of attribute
        if delete_chars then
          if a.title.include? chars_to_delete
                then
                name = a.title
                name.gsub!(chars_to_delete,'')
                result_names_array.push(error_details = {
                                     :type => "ERROR",
                                     :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + a.uri  ,
                                     :api => server + a.uri,
                                     :message => 'The new name of the attribute is (' + name + ').'
                                     })
                  # count objects
                counter_names_err += 1

                a.meta['title'] = name
                a.save
                else
                counter_names_ok += 1
              end
          else
          end

      folder_uri = a.content['dimension']
      # Pull folder from cache and compare the titles
      # IF checks if the folder exists and if the name is same and one more check if the folder is not deleted form GD GUI (deprecated)
      if folder_cache.key?(folder_uri) && folder_cache[folder_uri].title  == "Date and Time" && !folder_cache[folder_uri].deprecated

         #push info detail to result array
          result_array.push(error_details = {
                               :type => "INFO",
                               :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + a.uri  ,
                               :api => server + a.uri,
                               :message => 'The attribute (' + a.title + ') is already in folder "Date and Time".'
                               })
            # count objects
            counter_ok += 1

      else
          #push info detail to result array
          result_array.push(error_details = {
                               :type => "ERROR",
                               :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + a.uri  ,
                               :api => server + a.uri,
                               :message => 'The attribute (' + a.title + ') has been moved to "Date and Time" folder.'
                               })
            # count objects
        counter_err += 1

        if all_folders.key?("Date and Time")
          # "we have it so we just need to assign it"
      a.content['dimension'] = all_folders["Date and Time"]
      a.save
        else
          # we have to create it first
          folder = create_folder(project, "Date and Time")
          folder_cache[folder.uri] = folder
              #refresh folders
              client.get("#{project.md['query']}/dimensions")['query']['entries'].map do |i|
              all_folders.[]=(i['title'],i['link'])
              end
              all_folders.values.uniq
      # Now assign
      a.content['dimension'] = folder.uri
      a.save
        end

      end
    end
    end
    #save info about dataset into the result variable
    if delete_chars then
    $result.push({:section => 'The Time attributes titles changes.', :OK => counter_names_ok, :ERROR => counter_names_err, :output => result_names_array})
    else end
    $result.push({:section => 'The Time attributes folders changes.', :OK => counter_ok, :ERROR => counter_err, :output => result_array})

    result_array = []
    counter_ok = 0
    counter_err = 0
  end

end


#print out the result
puts $result.to_json

GoodData.disconnect
