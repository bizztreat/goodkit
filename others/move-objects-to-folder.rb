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

development_project.datasets.each do |dataset|

  if dataset.attributes.count > 0

    # check included and excluded tags
    if tags_included.empty? || !(dataset.tag_set & tags_included).empty?
      if (dataset.tag_set & tags_excluded).empty?

        # reset variables
        output = []
        counter_ok = 0
        counter_info = 0

        dataset_folder = client.get(development_project.md['query'] + '/dimensions')['query']['entries'].select { |folder| folder['title'] == dataset.title }

        if dataset_folder.empty?
          dataset_folder = create_attributes_folder(development_project, dataset.title)
        else
          dataset_folder = development_project.objects(dataset_folder.first['link'])
        end

        dataset.attributes.peach do |attribute|

          if attribute.content['dimension'].nil?

            output.push(details = {
                :type => 'INFO',
                :url => server + '#s=' + development_project.uri + '|objectPage|' + attribute.uri,
                :api => server + attribute.uri,
                :description => 'The attribute "' + attribute.title + '" has been moved to "' + dataset.title + '".'
            })
            counter_info += 1

            attribute.content['dimension'] = dataset_folder.uri
            attribute.save
          else
            attribute_folder = development_project.objects(attribute.content['dimension'])

            if attribute_folder.title == dataset.title && !attribute_folder.deprecated
              output.push(details = {
                  :type => 'OK',
                  :url => server + '#s=' + development_project.uri + '|objectPage|' + attribute.uri,
                  :api => server + attribute.uri,
                  :description => 'The attribute "' + attribute.title + '" is already in folder "' + dataset.title + '".'
              })
              counter_ok += 1
            else

              output.push(details = {
                  :type => 'INFO',
                  :url => server + '#s=' + development_project.uri + '|objectPage|' + attribute.uri,
                  :api => server + attribute.uri,
                  :description => 'The attribute "' + attribute.title + '" has been moved to "' + dataset.title + '".'
              })
              counter_info += 1

              attribute.content['dimension'] = dataset_folder.uri
              attribute.save
            end
          end
        end

        $result.push({:section => 'The dataset "' + dataset.title + '" has ' + (counter_ok + counter_info).to_s + ' attributes.', :OK => counter_ok, :INFO => counter_info, :ERROR => 0, :output => output})
      end
    end
  end
end

development_project.datasets.each do |dataset|

  if dataset.facts.count > 0

    # check included and excluded tags
    if tags_included.empty? || !(dataset.tag_set & tags_included).empty?
      if (dataset.tag_set & tags_excluded).empty?


        # reset variables
        output = []
        counter_ok = 0
        counter_info = 0

        dataset_folder = client.get(development_project.md['query'] + '/folders?type=fact')['query']['entries'].select { |folder| folder['title'] == dataset.title }

        if dataset_folder.empty?
          dataset_folder = create_facts_folder(development_project, dataset.title)
        else
          dataset_folder = development_project.objects(dataset_folder.first['link'])
        end

        dataset.facts.peach do |fact|

          if fact.content['folders'].nil?

            output.push(details = {
                :type => 'INFO',
                :url => server + '#s=' + development_project.uri + '|objectPage|' + fact.uri,
                :api => server + fact.uri,
                :description => 'The fact "' + fact.title + '" has been moved to "' + fact.title + '".'
            })
            counter_info += 1

            fact.content['folders'] = [dataset_folder.uri]
            fact.save
          else
            fact_folder = development_project.objects(fact.content['folders'].first)

            if fact_folder.title == dataset.title && !fact_folder.deprecated
              output.push(details = {
                  :type => 'OK',
                  :url => server + '#s=' + development_project.uri + '|objectPage|' + fact.uri,
                  :api => server + fact.uri,
                  :description => 'The fact "' + fact.title + '" is already in folder "' + dataset.title + '".'
              })
              counter_ok += 1
            else

              output.push(details = {
                  :type => 'INFO',
                  :url => server + '#s=' + development_project.uri + '|objectPage|' + fact.uri,
                  :api => server + fact.uri,
                  :description => 'The fact "' + fact.title + '" has been moved to "' + dataset.title + '".'
              })
              counter_info += 1

              fact.content['folders'] = [dataset_folder.uri]
              fact.save
            end
          end
        end

        $result.push({:section => 'The dataset "' + dataset.title + '" has ' + (counter_ok + counter_info).to_s + ' facts.', :OK => counter_ok, :INFO => counter_info, :ERROR => 0, :output => output})
      end
    end
  end
end

#TODO remove empty folders

puts $result.to_json
client.disconnect