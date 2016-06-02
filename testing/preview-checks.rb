require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# prepare all parameters options
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

# change the tag and the name to check here
tag = 'preview'
name_starting= 'ZOOM Preview - '

GoodData.with_connection(login: username, password: password, server: server) do |client|

  # get the devel project context
  devel = client.projects(devel)

  # get all metrics for given tag
  metrics = devel.metrics.select { |m| m.tag_set.include?(tag) }.sort_by(&:title)

  # for each metric
  metrics.each do |met|
    reports = met.usedby

    reports.select { |report| report["category"] == 'report' }.each { |r|
      # get only report objects and extract tags
      obj = GoodData::get(r["link"])
      # check exclude/include tag conditions
      if incl.to_s == '' || !(obj['report']['meta']['tags'].split(" ") & incl).empty? then
        if excl.to_s == '' || (obj['report']['meta']['tags'].split(" ") & excl).empty? then
          # check whether reports include preview tag
          if !obj['report']['meta']['tags'].include? "preview" then

            counter_err += 1
            err_array.push(error_details = {
                :type => "ERROR",
                :url => server + '/#s=/gdc/projects/' + devel.pid + '|analysisPage|head|' + "#{obj['report']['meta']['uri']}",
                :api => server + "/#{obj['report']['meta']['uri']}",
                :title => r['title'],
                :description => "Report not tagged as preview."
            })
          end
        end
      end
    }

  end

  # prepare part of the results
  $result.push({:section => 'Reports contains preview metric, not tagged as Preview', :OK => devel.metrics.count - counter_err, :ERROR => counter_err, :output => err_array})
  #reset output variables
  counter_ok = 0
  counter_err = 0
  err_array = []

  # get all metrics
  metrics.each do |met|
    # check exclude/include tag conditions
    if incl.to_s == '' || !(met.tag_set & incl).empty? then
      if excl.to_s == '' || (met.tag_set & excl).empty? then
        # get folder part of the metric metadata
        folder = met.content["folders"]

        # check for the correct folder or if folder is not set print the metric
        if folder.nil? then
          counter_err += 1
          err_array.push(error_details = {
              :type => "ERROR",
              :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + met.uri,
              :api => server + met.uri,
              :title => met.title,
              :message => "Metric is not in folder."
          })

        else
          obj = GoodData::get(folder[0])
          #puts obj['folder']['meta']['title']
          if !obj['folder']['meta']['title'].include? "ZOOM Preview" then

            counter_err += 1
            err_array.push(error_details = {
                :type => "ERROR",
                :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + met.uri,
                :api => server + met.uri,
                :title => met.title,
                :description => "Metric is not in Zoom Preview folder."
            })
          end
        end
      end
    end
  end
  # push result to the result array
  $result.push({:section => 'Metric is not in specific Zoom Preview folder or in any folder.', :OK => devel.metrics.count - counter_err, :ERROR => counter_err, :output => err_array})
  #reset output variables
  counter_ok = 0
  counter_err = 0
  err_array = []

  # get all reports for given tag
  reports = devel.reports.select { |m| m.tag_set.include?(tag) }.sort_by(&:title)

  # for each report
  reports.each do |rep|
    # check exclude/include tag conditions
    if incl.to_s == '' || !(rep.tag_set & incl).empty? then
      if excl.to_s == '' || (rep.tag_set & excl).empty? then

        # get folder/domain part of the metadata
        folders = rep.content["domains"]
        # check if report is in preview folder/domain
        if (folders.to_s == '[]') || folders.nil? then
          counter_err += 1
          err_array.push(error_details = {
              :type => "ERROR",
              :url => server + '/#s=/gdc/projects/' + devel.pid + '|analysisPage|' + rep.uri,
              :api => server + rep.uri,
              :title => rep.title,
              :description => "Reports is not in any folder"
          })

        else
          obj = GoodData::get(folders[0])
          #puts obj['domain']['meta']['title']
          if !obj['domain']['meta']['title'].include? "ZOOM Preview" then
            counter_err += 1
            err_array_3.push(error_details = {
                :type => "ERROR",
                :url => server + '/#s=/gdc/projects/' + devel.pid + '|analysisPage|' + rep.uri,
                :api => server + rep.uri,
                :title => rep.title,
                :description => "Reports is not in Zoom Preview folder"
            })
          end
        end
      end
    end
  end
  # push result to the result array
  $result.push({:section => 'Reports not in specific Zoom Preview folder or in any folder.', :OK => devel.reports.count - counter_err, :ERROR => counter_err, :output => err_array})

  #reset output variables
  counter_ok = 0
  counter_err = 0
  err_array = []

  reports.each do |rep|
    # check exclude/include tag conditions
    if incl.to_s == '' || !(rep.tag_set & incl).empty? then
      if excl.to_s == '' || (rep.tag_set & excl).empty? then
        # get all objects that use report
        using_reports = rep.usedby

        # select only dashboards from objects that used report
        using_reports.select { |dash| dash["category"] == 'projectDashboard' }.each { |d|
          # get only report objects and extract tags
          obj = GoodData::get(d["link"])

          # check whether reports include preview tag
          if !obj['projectDashboard']['meta']['title'].include? "Zoom preview" then

            counter_err += 1
            err_array.push(error_details = {
                :type => "ERROR",
                :url => server + '/#s=/gdc/projects/' + devel.pid + '|analysisPage|' + rep.uri,
                :api => server + rep.uri,
                :title => rep.title,
                :description => "Reports is not on Preview dashboard"
            })

          end

        }

      end
    end
  end

  $result.push({:section => 'Reports tagged Preview not in Preview dashboard', :OK => devel.reports.count - counter_err, :ERROR => counter_err, :output => err_array})
  #reset output variables
  counter_ok = 0
  counter_err = 0
  err_array = []

  # ------------ VARIABLES --------------
  GoodData.with_project(devel) do |project|
    project.variables.each do |var|
      # check exclude/include tag conditions
      if incl.to_s == '' || !(var.tag_set & incl).empty? then
        if excl.to_s == '' || (var.tag_set & excl).empty? then
          # continue with variable tags check
          if var.title.include?(name_starting) then
            if var.tags.include?(tag) then
            else
              counter_err += 1
              err_array.push(error_details = {
                  :type => "ERROR",
                  :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + var.uri,
                  :api => server + var.uri,
                  :title => var.title,
                  :description => "The variable is missing the 'preview' as a tag."
              })
            end
          end
          if var.tags.include?(tag) then
            if var.title.include?(name_starting) then
            else
              counter_err += 1
              err_array.push(error_details = {
                  :type => "ERROR",
                  :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + var.uri,
                  :api => server + var.uri,
                  :title => var.title,
                  :description => "The variable with the 'preview' as a tag is missing 'ZOOM Preview - ' in the title."
              })
            end
          end
        end
      end
    end

  end
  $result.push({:section => 'Variable tags and titles errors', :OK => 0, :ERROR => counter_err, :output => err_array})
  #reset output variables
  counter_ok = 0
  counter_err = 0
  err_array = []
  # ------------ VARIABLES -----------
  #---  Check metrics that depend on variables tagged "preview" but are not preview
  # reset counter
  counter_err = 0
  GoodData.with_project(devel) do |project|
    project.variables.each do |var|
      # check exclude/include tag conditions
      if incl.to_s == '' || !(var.tag_set & incl).empty? then
        if excl.to_s == '' || (var.tag_set & excl).empty? then
          if var.tag_set.include?(tag) then
            variables = var.usedby
            variables.select { |v| v["category"] == 'metric' }.each { |m|
              metric = GoodData::MdObject[m["link"]]
              if !metric.tag_set.include?(tag) then
                counter_err += 1
                err_array.push(error_details = {
                    :type => "ERROR",
                    :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + metric.uri,
                    :api => server + metric.uri,
                    :title => metric.title,
                    :description => "The metric is using 'preview' variables, but is not tagged."
                })
              end
            }
          end
        end
      end
    end
  end

  $result.push({:section => "Not tagged metrics using 'preview' variables.", :OK => 0, :ERROR => counter_err, :output => err_array})
  #reset output variables
  counter_ok = 0
  counter_err = 0
  err_array = []
  #----------Check metrics and reports that are in folder starting with "ZOOM Preview - " are also tagged "preview"
    #prepare all folders first
    all_folders={}
    client.get("#{devel.md['query']}/folders")['query']['entries'].map do |i|
      all_folders.[]=(i['title'], i['link'])
    end
    all_folders.values.uniq

    # check all metrics
  GoodData.with_project(devel) do |project|
    project.metrics.peach do |met|
      if incl.to_s == '' || !(met.tag_set & incl).empty? then
        if excl.to_s == '' || (met.tag_set & excl).empty? then
         if met.tag_set.include?(tag) then
      if  met.content["folders"].to_s != "" then
        if all_folders.key(met.content["folders"].first.to_s).to_s.include?(name_starting) then
          if !met.tag_set.include?(tag) then
          counter_err += 1
          err_array.push(error_details = {
              :type => "ERROR",
              :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + met.uri,
              :api => server + met.uri,
              :title => met.title,
              :description => "The metric from preview folder is not tagged by the preview tag."
          })
        else
          counter_ok += 1
          err_array.push(error_details = {
              :type => "OK",
              :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + met.uri,
              :api => server + met.uri,
              :title => met.title,
              :description => "The metric from preview folder is alredy tagged by the preview tag."
          })

          end
          end
          end
        end
        end
      end
    end
 end
 $result.push({:section => "Metrics from preview folder have been checked for the preview tag.", :OK => counter_ok, :ERROR => counter_err, :output => err_array})
 #reset output variables
 counter_ok = 0
 counter_err = 0
 err_array = []
 #----------check if metric depend on not preview variable

   # check all metrics
 GoodData.with_project(devel) do |project|
   project.metrics.each do |met|
     error = 0
     if incl.to_s == '' || !(met.tag_set & incl).empty? then
       if excl.to_s == '' || (met.tag_set & excl).empty? then
          if met.tag_set.include?(tag) then
         objects = met.using
         objects.select { |object| object["category"] == 'attribute' }.each { |obj|
                   obj = devel.attributes(obj["link"])
                 if  !obj.tags.to_s.split(" ").include?(tag) then
                  error = 1
                 end
                 }

         if error == 1 then
         counter_err += 1
         err_array.push(error_details = {
             :type => "ERROR",
             :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + met.uri,
             :api => server + met.uri,
             :title => met.title,
             :description => "The metric depends on not preview variable"
         })
       else
         counter_ok += 1
         err_array.push(error_details = {
             :type => "OK",
             :url => server + '/#s=/gdc/projects/' + devel.pid + '|objectPage|' + met.uri,
             :api => server + met.uri,
             :title => met.title,
             :description => "The metric does not depend on not preview variable"
         })

       end
       end
       end
       end
       end
     end
$result.push({:section => "Check if metric depends on not preview variable.", :OK => counter_ok, :ERROR => counter_err, :output => err_array})

end

puts $result.to_json

GoodData.disconnect
