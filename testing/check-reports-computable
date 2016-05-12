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
# get credentials from user parameters
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

counter_ok = 0
counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

GoodData.with_connection(username, password) do |client|

        # connect to project and check if the report is computable checks if there is an error and then print the report with error
        GoodData.with_project(devel) do |project|
          # select original reports include and exclude tags
        reports = project.reports.select { |r| incl.to_s == '' || !(r.tag_set & incl).empty? }.sort_by(&:title)
          reports = reports.select { |r| excl.to_s == '' || (r.tag_set & excl).empty? }.sort_by(&:title)

                reports.peach do |r|
                    begin
                            counter_ok += 1
                            r.definition.execute
                    rescue
                              counter_err += 1
                              err_array.push(error_details = {
                                  :type => "ERROR",
                                  :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + r.uri,
                                  :api => server + r.uri,
                                  :title => r.title,
                                  :message => "This report is not computable."
                              })
                    end
                end
                # prepare part of the results
                $result.push({:section => 'Uncomputable reports', :OK => counter_ok, :ERROR => counter_err, :output => err_array})
            end
end

puts $result.to_json

GoodData.disconnect
