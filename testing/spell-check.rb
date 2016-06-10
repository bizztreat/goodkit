require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'
require 'spellchecker' #https://dbader.org/blog/spell-checking-latex-documents-with-aspell


def check_misspelled(spell_checker_result)

  misspelled_words = []
  spell_checker_result.each do |result|

    unless result[:correct]
      misspelled_words.push(error = {error: result[:original], suggestions: result[:suggestions].join(', ')})
    end
  end

  misspelled_words
end

options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get all parameters - username, password and project id
username = options[:username]
password = options[:password]
devel = options[:devel]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then
  server = 'https://secure.gooddata.com'
end

# variables for standard output
counter_ok = 0
counter_err = 0
err_array = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to gooddata
GoodData.with_connection(login: username, password: password, server: server) do |client|

  # connect to project
  GoodData.with_project(devel) do |project|

    # checking dashboards and tabs
    project.dashboards.each do |dashboard|

      # checking dashboards name
      misspelled_words = check_misspelled(Spellchecker.check(dashboard.title.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '/#s=/gdc/projects/' + devel + '|projectDashboardPage|' + dashboard.uri,
            :api => server + dashboard.uri,
            :title => '"' + misspelled_word[:error] + '"' +' in dashboards name '+ dashboard.title,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end

      # checking dashboards description
      misspelled_words = check_misspelled(Spellchecker.check(dashboard.summary.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '/#s=/gdc/projects/' + devel + '|projectDashboardPage|' + dashboard.uri,
            :api => server + dashboard.uri,
            :title => '"' + misspelled_word[:error] + '"' +' in dashboards description '+ dashboard.summary,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end

      dashboard.tabs.each do |tab|

        # checking tab name
        misspelled_words = check_misspelled(Spellchecker.check(tab.title.gsub('-', ' ').delete('()')))
        misspelled_words.each do |misspelled_word|

          counter_err += 1
          err_array.push(error_details = {
              :type => 'ERROR',
              :url => server + '/#s=/gdc/projects/' + devel + '|projectDashboardPage|' + dashboard.uri + '|' + tab.identifier,
              :api => server + dashboard.uri,
              :title => '"' + misspelled_word[:error] + '"' + ' in tab name '+ dashboard.title + ' - ' + tab.title,
              :description => 'Suggestion: ' + misspelled_word[:suggestions]
          })
        end
      end
    end

    # checking metrics name
    project.metrics.each do |metric|
      misspelled_words = check_misspelled(Spellchecker.check(metric.title.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + metric.uri,
            :api => server + metric.uri,
            :title => '"' + misspelled_word[:error] + '"' + ' in metric name '+ metric.title,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end
    end

    # checking metrics description
    project.metrics.each do |metric|
      misspelled_words = check_misspelled(Spellchecker.check(metric.summary.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '#s=/gdc/projects/' + devel + '|objectPage|' + metric.uri,
            :api => server + metric.uri,
            :title => '"' + misspelled_word[:error] + '"' + ' in description '+ metric.summary,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end
    end

    # checking reports name
    project.reports.each do |report|
      misspelled_words = check_misspelled(Spellchecker.check(report.title.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + report.uri,
            :api => server + report.uri,
            :title => '"' + misspelled_word[:error] + '"' + ' in report name '+ report.title,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end
    end

    # checking reports description
    project.reports.each do |report|
      misspelled_words = check_misspelled(Spellchecker.check(report.summary.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + report.uri,
            :api => server + report.uri,
            :title => '"' + misspelled_word[:error] + '"' + ' in report description '+ report.summary,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end
    end

    # checking facts name
    project.facts.each do |fact|
      misspelled_words = check_misspelled(Spellchecker.check(fact.title.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + fact.uri,
            :api => server + fact.uri,
            :title => '"' + misspelled_word[:error] + '"' + ' in fact name '+ fact.title,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end
    end

    # checking facts description
    project.facts.each do |fact|
      misspelled_words = check_misspelled(Spellchecker.check(fact.summary.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + fact.uri,
            :api => server + fact.uri,
            :title => '"' + misspelled_word[:error] + '"' + ' in fact description ' + fact.summary,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end
    end

    # checking attributes name
    project.attributes.each do |attribute|
      misspelled_words = check_misspelled(Spellchecker.check(attribute.title.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + attribute.uri,
            :api => server + attribute.uri,
            :title => '"' + misspelled_word[:error] + '"' + ' in attribute ' + attribute.title,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end
    end

    # checking attributes description
    project.attributes.each do |attribute|
      misspelled_words = check_misspelled(Spellchecker.check(attribute.summary.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + attribute.uri,
            :api => server + attribute.uri,
            :title => '"' + misspelled_word[:error] + '"' + ' in attribute description ' + attribute.summary,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end
    end

    # checking datasets name
    project.datasets.each do |dataset|
      misspelled_words = check_misspelled(Spellchecker.check(dataset.title.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + dataset.uri,
            :api => server + dataset.uri,
            :title => '"' + misspelled_word[:error] + '"' + ' in dataset name '+ dataset.title,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end
    end

    # checking datasets description
    project.datasets.each do |dataset|
      misspelled_words = check_misspelled(Spellchecker.check(dataset.summary.gsub('-', ' ').delete('()')))
      misspelled_words.each do |misspelled_word|

        counter_err += 1
        err_array.push(error_details = {
            :type => 'ERROR',
            :url => server + '#s=/gdc/projects/' + devel + '|analysisPage|head|' + dataset.uri,
            :api => server + dataset.uri,
            :title => '"' + misspelled_word[:error] + '"' + ' in dataset description '+ dataset.summary,
            :description => 'Suggestion: ' + misspelled_word[:suggestions]
        })
      end
    end

    # prepare part of the results
    $result.push({:section => 'Spell Check name and description in dashboards, tabs, metrics, reports, facts, attributes and datasets', :OK => counter_ok, :ERROR => counter_err, :output => err_array})

    puts $result.to_json

  end

end

GoodData.disconnect