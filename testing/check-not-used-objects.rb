require 'gooddata'
require 'optparse'

def isDateOrTimeAttribute(attribute)

  excludeIdentifiers = %w(date day.in.month day.in.quarter day.in.euweek day.in.week day.in.year month month.in.quarter
  month.in.year quarter quarter.in.year euweek euweek.in.quarter euweek.in.year week.in.quarter week week.in.year year
  attr.time.ampm attr.time.hour.of.day attr.time.minute attr.time.minute.of.day attr.time.second attr.time.second.of.day)

  excludeIdentifiers.include? attribute.identifier[0..attribute.identifier.rindex('.')-1] or excludeIdentifiers.include? attribute.identifier[attribute.identifier.index('.')+1..-1]
end

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:tags_included] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:tags_included] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]
tags_included = options[:tags_included].to_s.split(',')
tags_excluded = options[:tags_excluded].to_s.split(',')

counter_ok = 0
counter_info = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to project context
development_project = client.projects(development_project)

# find unused reports
development_project.reports.each do |report|

  # check included and excluded tags
  if tags_included.empty? || !(report.tag_set & tags_included).empty?
    if (report.tag_set & tags_excluded).empty?

      objects = report.usedby

      counter_objects = objects.select { |object| object['category'] == 'projectDashboard' }.length

      # safe the result if there is ZERO project dashboards that are using the report
      if counter_objects == 0

        output.push(details = {
            :type => 'INFO',
            :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + report.uri,
            :api => server + report.uri,
            :title => report.title,
            :description => 'This report ('+ report.title + ') is not used by any project dashboard'
        })
        counter_info += 1
      else
        counter_ok += 1
      end
    end
  end
end

$result.push({:section => 'Facts which have not been used in any object (metric or report).', :OK => counter_ok, :INFO => counter_info, :ERROR => 0, :output => output})


# reset variables for counting errors
output = []
counter_ok = 0
counter_info = 0

# find unused attributes
development_project.attributes.each do |attribute|

  # check included and excluded tags
  if tags_included.empty? || !(attribute.tag_set & tags_included).empty?
    if (attribute.tag_set & tags_excluded).empty?
      unless isDateOrTimeAttribute(attribute)

        counter_objects = 0
        objects = attribute.usedby

        counter_objects += objects.select { |object| object['category'] == 'metric' }.length
        counter_objects += objects.select { |object| object['category'] == 'report' }.length

        # safe the result if there is ZERO objects that are using the attribute
        if counter_objects == 0

          output.push(details = {
              :type => 'INFO',
              :url => server + '/#s=' + development_project.uri + '|objectPage|' + attribute.uri,
              :api => server + attribute.uri,
              :title => attribute.title,
              :description => 'This attribute ('+ attribute.title + ') is not used by any object'
          })
          counter_info += 1
        else
          counter_ok += 1
        end
      end
    end
  end
end

$result.push({:section => 'Attributes which have not been used in any object (metric or report).', :OK => counter_ok, :INFO => counter_info, :ERROR => 0, :output => output})

# reset variables for counting errors
output = []
counter_ok = 0
counter_info = 0

# find unused facts
development_project.facts.each do |fact|

  # check included and excluded tags
  if tags_included.empty? || !(fact.tag_set & tags_included).empty?
    if (fact.tag_set & tags_excluded).empty?

      counter_objects = 0
      objects = fact.usedby

      counter_objects += objects.select { |object| object['category'] == 'metric' }.length
      counter_objects += objects.select { |object| object['category'] == 'report' }.length

      # safe the result if there is ZERO objects that are using the fact
      if counter_objects == 0

        output.push(details = {
            :type => 'INFO',
            :url => server + '/#s=' + development_project.uri + '|objectPage|' + fact.uri,
            :api => server + fact.uri,
            :title => fact.title,
            :description => 'This fact ('+ fact.title + ') is not used by any object'
        })
        counter_info += 1
      else
        counter_ok += 1
      end
    end
  end
end

$result.push({:section => 'Facts which have not been used in any object (metric or report).', :OK => counter_ok, :INFO => counter_info, :ERROR => 0, :output => output})
puts $result.to_json

client.disconnect
