#This script moves all FACTS and ATTRIBUTES to a folder that has the same name as the dataset in which they are
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }

end.parse!

# assign username and password to variables
 username = options[:username]
 password = options[:password]
 devel = options[:devel]
 server = options[:server]
 incl = options[:incl]
 excl = options[:excl]

 # make arrays from incl and excl parameters
 if incl.to_s != ''
 incl = incl.split(",")
 end

 if excl.to_s != ''
 excl = excl.split(",")
 end

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end


# variables for standard output
counter_ok = 0
counter_err = 0
result_array = []
$result = []

# Method for creating a folder for attributes
def create_folder(project, title, description = "")
  res = project.client.post(project.md['obj'], {"dimension":
  {"meta":
    {"title":title,"summary":description,"tags":"","deprecated":0},"content":{"attributes":[]}}})
  project.objects(res['uri'])
end

# Method for creating a folder for facts
def create_facts_folder(project, title, description = "")
  payload = {
    folder: {
      content: {
      entries: [],
      type: ['fact']
    },
    meta: {
      title: title,
      summary: description
    }
  }}

  res = project.client.post(project.md['obj'], payload)
  project.objects(res['uri'])
end

# turn off logging for clear output
GoodData.logging_off

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|

# connect to project
  GoodData.with_project(devel) do |project|
    # -----------ATTRIBUTES----------------
# Let's cache folders with attributes to speed things up
folder_uris = project.attributes.map { |a| a.content['dimension'] }.uniq.compact
folder_cache = folder_uris.reduce({}) { |a, e| a[e] = project.objects(e); a }
# Let's cache all the folders in project to check if the new folder is needed
all_folders={}
client.get("#{project.md['query']}/facts")['query']['entries'].map do |i|
     all_folders.[]=(i['title'],i['link'])
 end
all_folders.values.uniq
# start with datasets and check incl and excl tags
project.datasets.each do |dataset|
  if incl.to_s == '' || !(dataset.tag_set & incl).empty? then
    if excl.to_s == '' || (dataset.tag_set & excl).empty? then
  dataset.attributes.each do |a|

  folder_uri = a.content['dimension']
  # Pull folder from cache and compare the titles
  if folder_cache.key?(folder_uri) && folder_cache[folder_uri].title  == dataset.title && !folder_cache[folder_uri].deprecated
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
  if all_folders.key?(dataset.title)
    a.content['dimension'] = all_folders[dataset.title]
    a.save
    # "we have it so we just need to assign it"
  else
    # we have to create it first
    folder = create_folder(project, dataset.title)
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
#save info about dataset into the result variable
count = (counter_ok + counter_err).to_s
if count != "0" then
#save info about dataset into the result variable
$result.push({:section => 'The dataset "' + dataset.title + '" has ' + count + ' attributes.', :OK => counter_ok, :ERROR => counter_err, :output => result_array})
else
end
result_array = []
counter_ok = 0
counter_err = 0
end
end
end

    # -----------FACTS----------------
     # Let's cache the folders with facts to speed things up
     folder_cache = client.get(project.md['query'] + '/folders?type=fact')['query']['entries'].reduce({}) do |a, e|
         a[e['link']] = project.objects(e['link'])
         a
       end

       # Let's cache all the folders in project to check if the needed folder already exists
       all_folders_facts={}
     client.get(project.md['query'] + '/folders?type=fact')['query']['entries'].map do |i|
              all_folders_facts.[]=(i['title'],i['link'])
          end
       all_folders_facts.values.uniq
      # start with datasets and check incl and excl tags
      project.datasets.each do |dataset|
        if incl.to_s == '' || !(dataset.tag_set & incl).empty? then
          if excl.to_s == '' || (dataset.tag_set & excl).empty? then
       # Go facts
       dataset.facts.each do |f|
         # Pull folder from cache and compare the titles
         if f.content.key?('folders') && folder_cache[f.content['folders'].first].title  == dataset.title && !folder_cache[f.content['folders'].first].deprecated

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
           if all_folders_facts.key?(dataset.title)
             # "we have it so we just need to assign it"
             f.content['folders'] = [all_folders_facts[dataset.title]]
             f.save

           else
             # we have to create a folder first
            folder = create_facts_folder(project, dataset.title)
            folder_cache[folder.uri] = folder
        # refresh folder_cache
        all_folders_facts={}
      client.get(project.md['query'] + '/folders?type=fact')['query']['entries'].map do |i|
               all_folders_facts.[]=(i['title'],i['link'])
           end
        all_folders_facts.values.uniq

           end
           # Now assign
          f.content['folders'] = [all_folders_facts[dataset.title]]
          f.save
           end
         end
        #save info about dataset into the result variable
        count = (counter_ok + counter_err).to_s
      if count != "0" then
       # Push evrything about dataset to result variable
       $result.push({:section => 'The dataset "' + dataset.title + '" has ' + count + ' facts.', :OK => counter_ok, :ERROR => counter_err, :output => result_array})
      else
      end
       # Reset variables
       result_array = []
       counter_ok = 0
       counter_err = 0
       end
    end
  end
  
end
end
#print out the result
puts $result.to_json

GoodData.disconnect
