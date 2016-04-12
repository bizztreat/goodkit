#Fix time attributes - Moving attributes to own folders and renaming attributes
# FOLDERS parametr (true/false) - delete empty folders or not
# MAIN parametr (string) - The Data set name of the main Date and Time dimension
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# ---------------------METHODS---------------------
# Method for creating a folder
def create_folder(project, title, description = "")
  res = project.client.post(project.md['obj'], {"dimension":
  {"meta":
    {"title":title,"summary":description,"tags":"","deprecated":0},"content":{"attributes":[]}}})
  project.objects(res['uri'])
end

# Method Create a folder name from Dataset name
def create_folder_name(title, main_DD)
if title == main_DD then
name = "Date and Time"
else
name = title.sub('(', '')
name = name.sub(')', '')
name = name.sub('_ts', '')
name = name.sub('_date', '')
name = name.sub('_', '')
name = name.sub('Date', 'Date -')
name = name.split(/(?=[A-Z])/).join(' ').upcase
name = name.split.map(&:capitalize).join(' ')
name = name.sub('D D D', 'DDD')
end
end

# Method Create a folder name from Dataset name
def create_attribute_name(attr_title, dataset_title, main_DD, attr_identifier)
  first_name = ""
  case attr_identifier[attr_identifier.index('.')+1..-1]
  when 'date' then first_name = 'Date'
  when 'day.in.month' then first_name = 'Day of Month'
  when 'day.in.quarter' then first_name = 'Day of Quarter'
  when 'day.in.euweek' then first_name = 'Day of Week (Mon-Sun)'
  when 'day.in.week' then first_name = 'Day of Week (Sun-Sat)'
  when 'day.in.year' then first_name = 'Day of Year'
  when 'month' then first_name = 'Month/Year'
  when 'month.in.quarter' then first_name = 'Month of Quarter'
  when 'month.in.year' then first_name = 'Month'
  when 'quarter' then first_name = 'Quarter'
  when 'quarter.in.year' then first_name = 'Quarter/Year'
  when 'euweek' then first_name = 'Week (Mon-Sun)'
  when 'euweek.in.quarter' then first_name = 'Week (Mon-Sun) of Qtr'
  when 'euweek.in.year' then first_name = 'Week (Mon-Sun)/Year'
  when 'week' then first_name = 'Week (Sun-Sat)'
  when 'week.in.quarter' then first_name = 'Week (Sun-Sat) of Qtr'
  when 'week.in.year' then first_name = 'Week (Sun-Sat)/Year'
  when 'year' then first_name = 'Year'
  end
  if dataset_title == main_DD then
  name = first_name
  else
  name = first_name + ' ' + create_folder_name(dataset_title, main_DD).sub('Date ', '')
  end
end

# ----------------------PARAMETERS---------------------
options = {}
OptionParser.new do |opts|
  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-f', '--folders FOLDERS', 'Folders') { |v| options[:folders] = v } #  true/false delete empty folders
  opts.on('-m', '--main MAIN', 'Main') { |v| options[:main] = v }  # string name of main Date Time dataset
end.parse!

# get all parameters - username, password and project id
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]
folders_delete = options[:folders]
main = options[:main]

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

# turn off logging for clear output or ---> GoodData.logging_http_on
GoodData.logging_off

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|

# connect to project
  GoodData.with_project(devel) do |project|

  # Let's cache all the folders containing attributes to speed things up
   folder_uris = project.attributes.map { |a| a.content['dimension'] }.uniq.compact
   folder_cache = folder_uris.reduce({}) { |a, e| a[e] = project.objects(e); a }
  # Let's cache all the folders in project to check if our folder already exists and to get uri later
   all_folders={}
   client.get("#{project.md['query']}/dimensions")['query']['entries'].map do |i|
          all_folders.[]=(i['title'],i['link'])
      end
   all_folders.values.uniq

 # Let's start with DATASETS
   project.datasets.each do |d|
  # condition if it's DD
   if ['.dt'].any? { |word| d.identifier.include?(word) } then
  # Let's start with ATTRIBUTES
      d.attributes.each do |a|

        a.title = create_attribute_name(a.title, d.title, main_DD, a.identifier)
        a.title
        a.save

      # IF checks if the folder exists and if the name is same and one more check if the folder is not deleted from GD GUI (deprecated)
      if folder_cache.key?(a.content['dimension']) && folder_cache[a.content['dimension']].title  == create_folder_name(d.title, main_DD) && !folder_cache[a.content['dimension']].deprecated

         #push info detail to result array as INFO
          result_array.push(error_details = {
                               :type => "INFO",
                               :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + a.uri  ,
                               :api => server + a.uri,
                               :message => 'The attribute (' + a.title + ') is already in folder "' + create_folder_name(d.title, main_DD) + '".'
                               })
            # count objects
            counter_ok += 1
      else
          #push info detail to result array as ERROR
          result_array.push(error_details = {
                               :type => "ERROR",
                               :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + a.uri  ,
                               :api => server + a.uri,
                               :message => 'The attribute (' + a.title + ') has been moved to  folder "' + create_folder_name(d.title, main_DD) + '".'
                               })
            # count objects
        counter_err += 1
# ACTION -- do the changes
        if all_folders.key?(create_folder_name(d.title, main_DD))
          # "we have it so we just need to assign it"
      a.content['dimension'] = all_folders[create_folder_name(d.title, main_DD)]
      a.save
        else
          # we have to create it first
          folder = create_folder(project, create_folder_name(d.title, main_DD))
          folder_cache[folder.uri] = folder
              #refresh folder's list
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
  end

    #save info into the result variable
    $result.push({:section => 'The Time attributes folders changes.', :OK => counter_ok, :ERROR => counter_err, :output => result_array})

    result_array = []
    counter_ok = 0
    counter_err = 0


    #-----------DELETE EMPTY FOLDERS----------------
    if folders_delete then
       all_folders={}
       client.get("#{project.md['query']}/dimensions")['query']['entries'].map do |i|
              all_folders.[]=(i['title'],i['link'])
          end

      all_folders.each { |x, e|  if project.objects(e).content.to_s == '{"attributes"=>[]}' then
      object = project.objects(e)
      object.deprecated = 1
      object.save
      result_array.push(error_details = {
                           :type => "INFO",
                           :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + object.uri  ,
                           :api => server + object.uri,
                           :message => 'The folder (' + object.title + ') has been deleted.'
                           })
        # count objects
        counter_ok += 1


     end }
     $result.push({:section => 'The deleted folders.', :OK => counter_ok, :ERROR => counter_err, :output => result_array})
  end

end
end

#print out the result
puts $result.to_json

GoodData.disconnect
