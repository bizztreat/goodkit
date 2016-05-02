#MZ Check metrics for specific formatting, with an extension for comparing metric title and format together.
#For more information check procedure parameters
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
  # allowed metric format (any difference formatting is counted as an error) for example: "#,##0%" Always use ""
  opts.on('-f', '--format Format', 'Format') { |v| options[:format] = v }
  # Do you want to combinate checking metric format with checking a name of metric? (true=yes, false=no). for example: true
  opts.on('-c', '--check Check', 'Check') { |v| options[:check] = v }
  # If you set up "check_text_in_title" to "true", a format of metrics will be check just for metrics containing "text_in_title" in their title!
  opts.on('-t', '--title TITLE', 'Text in title') { |v| options[:title] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }


end.parse!

# get all parameters - username, password and project id
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


# allowed metric format (any difference formatting is counted as an error) for example: "#,##0%" Please youse "" for format!
format = options[:format]

# Do you want to combinate checking metric format with checking a name of metric? (true=yes, false=no). for example: true
check_text_in_title = options[:check]

# If you set up "check_text_in_title" to "true", a format of metrics will be check just for metrics containing "text_in_title" in their title!
text_in_title = options[:title]

# variables for standard output
counter_ok = 0
counter_err = 0
err_array = []
result = []

# turn off logging for clear output
GoodData.logging_off

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|

# connect to project
  GoodData.with_project(devel) do |project|
    # go through all metrics in the project
    project.metrics.pmap do |metric|
      #check tags first
      if incl.to_s == '' || !(metric.tag_set & incl).empty? then
        if excl.to_s == '' || (metric.tag_set & excl).empty? then
          # check just metric format or format and title together
          if (((metric.content['format'] != format) and !(check_text_in_title)) or ((metric.content['format'] != format) and (metric.title.include? text_in_title)))

          then
            # count errors and prepare details to the array
            counter_err += 1
            # save detail to the array
            err_array.push({
               :type => "ERROR",
               :url => server + '/#s=/gdc/projects/' + devel + '|objectPage|' + metric.uri,
               :api => server + metric.uri,
               :title => '',
               :description => "Suspicious metric formating detected."
            })

          else
            # count OK objects
            counter_ok += 1
          end
        end
      end
    end

    # prepare part of the results
    result.push({:section => 'Suspicious metric´s formating check.', :OK => counter_ok, :ERROR => counter_err, :output => err_array})
    puts result.to_json


  end
end
GoodData.disconnect
