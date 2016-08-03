require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# more info http://stackoverflow.com/questions/35447652/is-it-possible-change-attribute-folder-in-gooddata-project-by-ruby

# creating a folder for attributes
def create_attributes_folder(development_project, title, description = '')

  payload = {
      dimension: {
          meta: {
              title: title,
              summary: description,
              tags: '',
              deprecated: 0
          },
          content: {
              attributes: []
          }
      }
  }

  result = development_project.client.post(development_project.md['obj'], payload)
  development_project.objects(result['uri'])
end

# creating a folder for facts
def create_facts_folder(development_project, title, description = '')
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
      }
  }

  result = development_project.client.post(development_project.md['obj'], payload)
  development_project.objects(result['uri'])
end


options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_excluded] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

# variables for standard output
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# let's cache folders with attributes to speed things up
folder_uris = development_project.attributes.map { |attribute| attribute.content['dimension'] }.uniq.compact
folder_cache = folder_uris.reduce({}) { |a, e| a[e] = development_project.objects(e); a }

# let's cache all the folders in project to check if the new folder is needed
all_folders={}
client.get("#{development_project.md['query']}/facts")['query']['entries'].map do |folder|
  all_folders.[]=(folder['title'], folder['link'])
end

all_folders.values.uniq

development_project.datasets.each do |dataset|

  # check included and excluded tags
  if tags_included.empty? || !(dataset.tag_set & tags_included).empty?
    if (dataset.tag_set & tags_excluded).empty?

      # reset variables
      output = []
      counter_ok = 0
      counter_error = 0

      dataset.attributes.each do |attribute|

        folder_uri = attribute.content['dimension']
        # Pull folder from cache and compare the titles
        if folder_cache.key?(folder_uri) && folder_cache[folder_uri].title == dataset.title && !folder_cache[folder_uri].deprecated
          #push info detail to result array
          output.push(error_details = {
              :type => 'INFO',
              :url => server + '#s=' + development_project.uri + '|objectPage|' + attribute.uri,
              :api => server + attribute.uri,
              :description => 'The attribute "' + attribute.title + '" is already in folder "' + dataset.title + '".'
          })
          counter_ok += 1
        else
          #push info detail to result array
          output.push(error_details = {
              :type => 'ERROR',
              :url => server + '#s=' + development_project.uri + '|objectPage|' + attribute.uri,
              :api => server + attribute.uri,
              :description => 'The attribute "' + attribute.title + '" has been moved to "' + dataset.title + '".'
          })
          # count objects
          counter_error += 1
          if all_folders.key?(dataset.title)
            attribute.content['dimension'] = all_folders[dataset.title]
            attribute.save
            # "we have it so we just need to assign it"
          else
            # we have to create it first
            folder = create_attributes_folder(development_project, dataset.title)
            folder_cache[folder.uri] = folder
            #refresh folders
            client.get("#{development_project.md['query']}/dimensions")['query']['entries'].map do |dimension|
              all_folders.[]=(dimension['title'], dimension['link'])
            end
            all_folders.values.uniq
            # Now assign
            attribute.content['dimension'] = folder.uri
            attribute.save
          end
        end
      end
      count = (counter_ok + counter_error).to_s #TODO ??
      if count != '0'
        $result.push({:section => 'The dataset "' + dataset.title + '" has ' + count + ' attributes.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
      end
    end
  end
end

# let's cache the folders with facts to speed things up
folder_cache = client.get(development_project.md['query'] + '/folders?type=fact')['query']['entries'].reduce({}) do |a, e|
  a[e['link']] = project.objects(e['link'])
  a
end

# Let's cache all the folders in project to check if the needed folder already exists
all_folders_facts={}
client.get(development_project.md['query'] + '/folders?type=fact')['query']['entries'].map do |folder|
  all_folders_facts.[]=(folder['title'], folder['link'])
end
all_folders_facts.values.uniq

development_project.datasets.each do |dataset|

  # check included and excluded tags
  if tags_included.empty? || !(dataset.tag_set & tags_included).empty?
    if (dataset.tag_set & tags_excluded).empty?

      # reset variables
      output = []
      counter_ok = 0
      counter_error = 0

      dataset.facts.each do |fact|
        # Pull folder from cache and compare the titles
        if fact.content.key?('folders') && folder_cache[fact.content['folders'].first].title == dataset.title && !folder_cache[fact.content['folders'].first].deprecated

          #push info detail to result array
          output.push(error_details = {
              :type => 'INFO',
              :url => server + '#s=' + development_project.uri + '|objectPage|' + fact.uri,
              :api => server + fact.uri,
              :description => 'The fact "' + fact.title + '" is already in folder "' + dataset.title + '".'
          })
          counter_ok += 1
        else
          #push error detail to result array
          output.push(error_details = {
              :type => 'ERROR',
              :url => server + '#s=' + development_project.uri + '|objectPage|' + fact.uri,
              :api => server + fact.uri,
              :description => 'The fact "' + fact.title + '" has been moved to (' + dataset.title + ').'
          })
          counter_error += 1
          # Check folder if exists
          if all_folders_facts.key?(dataset.title)
            # "we have it so we just need to assign it"
            fact.content['folders'] = [all_folders_facts[dataset.title]]
            fact.save
          else
            # we have to create a folder first
            folder = create_facts_folder(development_project, dataset.title)
            folder_cache[folder.uri] = folder
            # refresh folder_cache
            all_folders_facts={}
            client.get(project.md['query'] + '/folders?type=fact')['query']['entries'].map do |i|
              all_folders_facts.[]=(i['title'], i['link'])
            end
            all_folders_facts.values.uniq

          end

          fact.content['folders'] = [all_folders_facts[dataset.title]]
          fact.save
        end
      end

      # save info about dataset into the result variable
      count = (counter_ok + counter_error).to_s
      if count != '0'
        $result.push({:section => 'The dataset "' + dataset.title + '" has ' + count + ' facts.', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
      end
    end
  end
end

puts $result.to_json
client.disconnect
