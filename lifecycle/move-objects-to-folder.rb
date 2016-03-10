#This script moves all FACTS and ATTRIBUTES to a folder that has the same name as the dataset in which they are
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

end.parse!

# assign username and password to variables
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end


# variables for standard output
counter_ok = 0
counter_err = 0
result_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off
#GoodData.logging_http_on

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|

# connect to project
  GoodData.with_project(devel) do |project|
  # -----------ATTRIBUTES---------------- 
  # Let's cache all the folders to speed things up
    folder_uris = project.attributes.map { |a| a.content['dimension'] }.uniq.compact
    folder_cache = folder_uris.reduce({}) { |a, e| a[e] = project.objects(e); a }

    project.datasets.each do |dataset|
    
    dataset.attributes.each do |a|
      folder_uri = a.content['dimension']
      # Pull folder from cache and compare the titles
      if folder_cache.key?(folder_uri) && folder_cache[folder_uri].title  == dataset.title
       
         #push info detail to result array
          result_array.push(error_details = {
                               :type => "INFO",
                               :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + a.uri  ,
                               :api => server + a.uri,
                               :message => 'The attribute (' + a.title + ') is already in folder (' + dataset.title + ').'
                               })
            # count objects
            counter_ok += 1

      else
          #push info detail to result array
          result_array.push(error_details = {
                               :type => "ERROR",
                               :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + a.uri  ,
                               :api => server + a.uri,
                               :message => 'The attribute (' + a.title + ') has been moved to (' + dataset.title + ').'
                               })
            # count objects
        counter_err += 1
        
        folder = folder_cache.values.find { |f| f.title } == dataset.title
        if folder
          # "we have it so we just need to assign it"
        else
          # we have to create it first
          folder = create_folder(project, dataset.title)
          folder_cache[folder.uri] = folder
     # refresh folder_cache     
    folder_uris = project.attributes.map { |a| a.content['dimension'] }.uniq.compact
    folder_cache = folder_uris.reduce({}) { |a, e| a[e] = project.objects(e); a }
        end
        # Now assign
       a.content['dimension'] = folder.uri
       a.save
      end
    end
     #save info about dataset into the result variable
     count = (counter_ok + counter_err).to_s
    #save info about dataset into the result variable
    $result.push({:section => 'The dataset "' + dataset.title + '" has ' + count + ' attributes.', :OK => counter_ok, :ERROR => counter_err, :output => result_array})          
    result_array = []
    counter_ok = 0
    counter_err = 0
  end
  # -----------FACTS---------------- 
  # Let's cache all the folders to speed things up
  folder_cache = client.get(project.md['query'] + '/folders?type=fact')['query']['entries'].reduce({}) do |a, e|
      a[e['link']] = project.objects(e['link'])
      a
    end
   # Go datasets
   project.datasets.each do |dataset|
    # Go facts
    dataset.facts.each do |f|
     # Prepare folder and compare with Dataset Name 
     folder = f.content.key?('folders') && f.content['folders'].is_a?(Enumerable) && f.content['folders'].first
     folder_title = folder_cache[folder] && folder_cache[folder].title
       
      # Pull folder from cache and compare the titles
      if f.content.key?('folders') && f.content['folders'].is_a?(Enumerable) && folder_title == dataset.title
         
         #push info detail to result array
          result_array.push(error_details = {
                               :type => "INFO",
                               :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + f.uri  ,
                               :api => server + f.uri,
                               :message => 'The fact (' + f.title + ') is already in folder (' + dataset.title + ').'
                               })
            # count info objects
            counter_ok += 1

      else
          #push error detail to result array
          result_array.push(error_details = {
                               :type => "ERROR",
                               :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + f.uri  ,
                               :api => server + f.uri,
                               :message => 'The fact (' + f.title + ') has been moved to (' + dataset.title + ').'
                               })
            # count error objects
            counter_err += 1
        # Check folder if exists
        condition = folder_cache[folder] && folder_cache[folder].title == dataset.title
        if condition
          # "we have it so we just need to assign it"
        else
          # we have to create a folder first
          folder = create_folder(project, dataset.title)
          folder_cache[folder.uri] = folder
     # refresh folder_cache     
  folder_cache = client.get(project.md['query'] + '/folders?type=fact')['query']['entries'].reduce({}) do |a, e|
      a[e['link']] = project.objects(e['link'])
      a
    end
        end
        # Now assign
       folder_array = []
       folder_array.push(folder.uri)
       f.content['folders'] = folder_array
       f.save

      end
    end
     #save info about dataset into the result variable
     count = (counter_ok + counter_err).to_s
    # Push evrything about dataset to result variable
    $result.push({:section => 'The dataset "' + dataset.title + '" has ' + count + ' facts.', :OK => counter_ok, :ERROR => counter_err, :output => result_array})          
    # Reset variables
    result_array = []
    counter_ok = 0
    counter_err = 0
    end

  end
end 

#print out the result
puts $result.to_json

GoodData.disconnect
