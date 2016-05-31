# Check reports if there is no deleted metric in the definition
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

# get credentials and project ids
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
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end

counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|

  # connect to devel project and get metric expression
  GoodData.with_project(devel) do |project|

    #get metric expression from devel project
    project.reports.each do |report|
      #check incl and excl tags
      if incl.to_s == '' || !(report.tag_set & incl).empty? then
        if excl.to_s == '' || (report.tag_set & excl).empty? then

          #cache metrics which are using on the report
          objects = report.definition.using

          #go through them
          objects.select { |object| object["category"] == 'metric' }.each { |m|

            obj = GoodData::get(m["link"])
            #check if the metric is deleted  ['deprecated'] == "1"
            if obj['metric']['meta']['deprecated'] == "1" then

              #push errors to error array
              counter_err += 1
              err_array.push(error_details = {
                  :type => "ERROR",
                  :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + m["link"],
                  :api => server + m["link"],
                  :title => obj['metric']['meta']['title'],
                  :description => "This report's metric has been deleted."
              })
            end
          }
        end
      end
      if counter_err != 0 then
        # save error lists to array and prepare for a json creation
        $result.push({:section => 'This report "' + report.title + '" contains deleted metrics', :OK => "0", :ERROR => counter_err, :output => err_array})
        counter_err = 0
      end
    end
  end
  # result as json_file
  puts $result.to_json

end
GoodData.disconnect