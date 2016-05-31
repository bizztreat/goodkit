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
    opts.on('-t', '--exclude EXCLUDE', 'Checked tag') { |v| options[:tag] = v }
end.parse!

# get credentials from input parameters
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]
incl = options[:incl]
excl = options[:excl]
tag = options[:tag]

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
if tag.to_s.empty? then tag = "cisco" end
stop = 0

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

# turn off GoodData logging
GoodData.logging_off

# connect to GoodData
GoodData.with_connection(login: username, password: password, server: server) do |client|

       # get the project context using Project ID from user input
       devel_project = client.projects(devel)
      #----------METRICS---------------------------
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

                #go through metrics
                objects = m.using
                objects.select { |object| object["category"] == 'metric' }.each { |obj|
                        obj = devel_project.metrics(obj["link"])
                      if  !obj.tags.to_s.split(" ").include?(tag) then
                        stop = 1
                      end
                      }
                #go through attributes
                objects = m.using
                objects.select { |object| object["category"] == 'attribute' }.each { |obj|
                          obj = devel_project.attributes(obj["link"])
                        if  !obj.tags.to_s.split(" ").include?(tag) then
                          stop = 1
                        end
                        }

                # if all objects include the tag, set the tag for metric as well
                if stop == 0 then
                    m.add_tag(tag)
                    m.save
                   # push the result to result_array
                   if tagset.include?(tag)  then
                     result_array.push(error_details = {
                         :type => "OK",
                         :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + m.uri,
                         :api => server + m.uri,
                         :title => m.title,
                         :description => 'The tagset of metric ('+ m.title + ') already include the tag ('+ tag + ').'
                     })
                     count_ok += 1
                   else
                   result_array.push(error_details = {
                       :type => "ERROR",
                       :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + m.uri,
                       :api => server + m.uri,
                       :title => m.title,
                       :description => 'The tag ('+ tag + ') has been added to the tagset of the metric.'
                   })
                   count_error += 1
                 end
                end
            end
          end
       end
    #save errors in the result variable
    $result.push({:section => 'Tag sets of these metrics have been checked and changed.', :OK => count_ok, :ERROR => count_error, :output => result_array})
    #reset variables
    result_array = []
    count_ok = 0
    count_error = 0
    stop = 0

    #----------REPORTS---------------------------
     # do all reports
     devel_project.reports.each do |r|
       #reset variables
       merge_tagset = []
       count_objs = 0
       # check all reports according to tag's rules
       if incl.to_s == '' || !(r.tag_set & incl).empty? then
         if excl.to_s == '' || (r.tag_set & excl).empty? then

           #tag set of original report
           tagset = r.tags.to_s.split(" ")

              #go through report's metrics
              objects = r.using
              objects.select { |object| object["category"] == 'metric' }.each { |obj|
                      obj = devel_project.metrics(obj["link"])
                    if  !obj.tags.to_s.split(" ").include?(tag) then
                      stop = 1
                    end
                    }
              #go through report's attributes
              objects = r.using
              objects.select { |object| object["category"] == 'attribute' }.each { |obj|
                        obj = devel_project.attributes(obj["link"])
                      if  !obj.tags.to_s.split(" ").include?(tag) then
                        stop = 1
                      end
                      }

              # if all objects include the tag, set the tag for metric as well
              if stop == 0 then
                  r.add_tag(tag)
                  r.save
                 # push the result to result_array
                 if tagset.include?(tag)  then
                   result_array.push(error_details = {
                       :type => "OK",
                       :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + r.uri,
                       :api => server + r.uri,
                       :title => r.title,
                       :description => 'The tagset of report ('+ r.title + ') already include the tag ('+ tag + ').'
                   })
                   count_ok += 1
                 else
                 result_array.push(error_details = {
                     :type => "ERROR",
                     :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + r.uri,
                     :api => server + r.uri,
                     :title => r.title,
                     :description => 'The tag ('+ tag + ') has been added to the tagset of the metric.'
                 })
                 count_error += 1
               end
              end
          end
        end
     end
  #save errors in the result variable
  $result.push({:section => 'Tag sets of these reports have been checked and changed.', :OK => count_ok, :ERROR => count_error, :output => result_array})

  end

#print out the result
puts $result.to_json

GoodData.disconnect
