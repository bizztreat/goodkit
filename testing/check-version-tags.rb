require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'json'

options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }

end.parse!

# collect parameters for connection and for project variable
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
counter_ok = 0
counter_err = 0
err_array = []
$result = []

# if whitelabel is not specified set to default domain
if server.to_s.empty?
  server = 'https://secure.gooddata.com'
end

GoodData.logging_off

GoodData.with_connection(login: username, password: password, server: server) do |client|

  # connect to project
  GoodData.with_project(devel) do |project|

    # check all reports for missing tags
    project.reports.each do |report|
      if incl.to_s == '' || !(report.tag_set & incl).empty? then
        if excl.to_s == '' || (report.tag_set & excl).empty? then

          tags = report.tags.gsub(/\s+/m, ' ').strip.split(" ")
          if !tags.any? { |tag| /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/.match(tag) }

          then

            # count errors and prepare details to the array
            counter_err += 1
            err_array.push({
                :type => "ERROR",
                :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + report.uri,
                :api => server + report.uri,
                :title => report.title,
                :description => "Report does not have a version tag."
            })
          else
            # count OK objects
            counter_ok += 1
          end
        end
      end
    end

    # prepare part of the results
    $result.push({:section => 'Reports without version tags', :OK => counter_ok, :ERROR => counter_err, :output => err_array})

    # check all metrics for missing tags
    project.metrics.each do |metric|
      if incl.to_s == '' || !(metric.tag_set & incl).empty? then
        if excl.to_s == '' || (metric.tag_set & excl).empty? then

          tags = metric.tags.gsub(/\s+/m, ' ').strip.split(" ")
          if !tags.any? { |tag| /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/.match(tag) }

          then
            # count errors and prepare details to the array
            counter_err += 1
            err_array.push({
                :type => "ERROR",
                :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + metric.uri,
                :api => server + metric.uri,
                :title => metric.title,
                :description => "Metric does not have a version tag."
            })
          else
            # count OK objects
            counter_ok += 1
          end
        end
      end
    end

    $result.push({:section => 'Metrics without version tags', :OK => counter_ok, :ERROR => counter_err, :output => err_array})

    puts $result.to_json

  end
end
GoodData.disconnect
