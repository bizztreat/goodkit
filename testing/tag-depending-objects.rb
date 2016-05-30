#Testing Report results between Start and Devel projects.
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
    opts.on('-d', '--develproject NAME', 'Devel Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
    opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
    opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }
end.parse!

# get credentials from input parameters
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

# variables for script results
result_array = []
count_ok = 0
count_error = 0
$result = []

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|

       # get the project context using Project ID from user input
       devel_project = client.projects(devel)

       # do all metrics
       devel_project.metrics.each do |m|
         #reset variables
         merge_tagset = []
         count_objs = 0
         # check all metrics according to tag's rules
         if incl.to_s == '' || !(m.tag_set & incl).empty? then
           if excl.to_s == '' || (m.tag_set & excl).empty? then

             #tag set of original metric
             tagset = m.tags.to_s.split(" ")

                #go through metrics objects
                objects = m.using
                objects.select { |object| object["category"] == 'metric' }.each { |obj|
                        obj = devel_project.metrics(obj["link"])
                        merge_tagset = obj.tags.to_s.split(" ") + tagset
                        count_objs += 1
                      }
                # if there is just one metrict, save merge tags and save
                if count_objs == 1 then
                   merge_tagset.uniq.each { |tag|
                    m.add_tag(tag.to_s)
                    m.save
                   }
                   # push the result to result_array
                   if tagset.sort.to_s == merge_tagset.uniq.sort.to_s then
                     result_array.push(error_details = {
                         :type => "OK",
                         :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + m.uri,
                         :api => server + m.uri,
                         :title => m.title,
                         :description => 'The tagset of metric ('+ m.title + ') is already updated.'
                     })
                     count_ok += 1
                   else
                   result_array.push(error_details = {
                       :type => "ERROR",
                       :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + m.uri,
                       :api => server + m.uri,
                       :title => m.title,
                       :description => 'The tagset of metric ('+ m.title + ') has been updated.'
                   })
                   count_error += 1
                 end
                end
            end
          end
       end
    #save errors in the result variable
    $result.push({:section => 'These metrics and their tagsets have been chaged.', :OK => count_ok, :ERROR => count_error, :output => result_array})
  end

#print out the result
puts $result.to_json

GoodData.disconnect
