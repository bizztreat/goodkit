# This script has to parts, the first part is used to generate JSON file containing values of attributes
# the second part of the script is used just for checking values from JSON file and project in devel parametr.
# For switching between these two parts please use parameter GENERATE ("true"/"false")
# To select what attributes should be checked please use parameter attributes
# check-attribute-values.rb -u user@company.com -p yourpassword -d projectspid -h https://secure.gooddata.com -a "Group,Abandoned" -g false
require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'rubygems'
require 'json'

# prepare all parameters options
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }
  opts.on('-i', '--include INCLUDE', 'Tag included') { |v| options[:incl] = v }
  opts.on('-e', '--exclude EXCLUDE', 'Tag excluded') { |v| options[:excl] = v }
  opts.on('-a', '--attributes ATTRIBUTES', 'Attributes') { |v| options[:atts] = v }
  opts.on('-g', '--generate GENERATE', 'Generate') { |v| options[:generate] = v } # if generate true, then the script works as a json generator

end.parse!

# get credentials from user parameters
username = options[:username]
password = options[:password]
pid = options[:devel]
server = options[:server]
incl = options[:incl]
excl = options[:excl]
atts = options[:atts]
generate = options[:generate]

if generate.to_s.empty? then
  generate = "false"
end

if atts.to_s != ''
  atts = atts.to_s.split(",")
end

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
error_array = []
result_array = []
$result = []
hash = {}
hash_final = {}

# turn off logging for clear output
GoodData.logging_off

GoodData.with_connection(login: username, password: password, server: server) do |client|

  # get the devel project context
  devel = client.projects(pid)
#----------------------------------------------------------------------------
#generate JSON file first
if generate == "true" then
  devel.attributes.each do |a|
    if incl.to_s == '' || !(a.tag_set & incl).empty? then
      if excl.to_s == '' || (a.tag_set & excl).empty? then
          if atts.include? a.title then
            values = []
            a.values.each do |v|
              v.each do |h|
                h.each do |k,v|
                  if v.include? pid then
                    else
                        values.push(v)
                    end
                  end
                end
            end
            # creating hash of results and merging output
              hash = {a.title => values}
              if hash_final == {}
                then hash_final = hash
              else
                hash_final = hash_final.merge(hash)
              end
            end
          end
        end
      end
      #write attributes and their values to the JSON file
      File.open("atts.json","w") do |f|
      f.write(hash_final.to_json)
    end
  end
#----------------------------------------------------------------------------
# read JSON file and check values
  if generate == "false" then
    # parse JSON file
    atts = JSON.parse( File.read('atts.json'))
    #check attributes if they are in JSON file
    devel.attributes.each do |a|
      #reset and prepare variables to collect missing and extra values
      missing = []
      extra = []
      if atts.has_key?(a.title) then
        # download attribute's values first
        values = []
        a.values.each do |v|
          v.each do |h|
            h.each do |k,v|
              if v.include? pid then else values.push(v) end
              end
            end
        end
        # Array list of misssing values
        missing =  values - atts[a.title]
        # Array list of extra values
        extra =  atts[a.title] - values
        #check if there is any inconsistency
        if missing.any? || extra.any? then
          counter_err += 1
          error_array.push(error_details = {
              :type => "ERROR",
              :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + a.uri,
              :api => server + a.uri,
              :title => a.title,
              :description => 'The attribute "' + a.title + '" is missing these values "' + missing.to_s + '" and contains extra values "' + extra.to_s + '".'
          })
        else
          counter_ok += 1
          result_array.push(error_details = {
              :type => "INFO",
              :url => server + '/#s=/gdc/projects/' + pid + '|objectPage|' + a.uri,
              :api => server + a.uri,
              :title => a.title,
              :description => 'The attribute`s "' + a.title + '" values are identical.'
          })
        end

      end
    end
    #push the result to the result file
    $result.push({:section => "Checking values of attributes results. ERRORS", :OK => 0, :ERROR => counter_err, :output => error_array})
    $result.push({:section => "Checking values of attributes results. OK", :OK => counter_ok, :ERROR => 0, :output => result_array})
  end
puts $result.to_json
end
GoodData.disconnect
