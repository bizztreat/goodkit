require 'gooddata'
require 'optparse'
require 'spellchecker'


def check_misspelled(spell_checker_result)

  misspelled_words = []
  spell_checker_result.each do |result|

    unless result[:correct]
      misspelled_words.push(error = {error: result[:original], suggestions: result[:suggestions].join(', ')})
    end
  end

  misspelled_words
end

# define options for script configuration
options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-d', '--development_project ID', 'Development Project') { |v| options[:development_project] = v }
  opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get credentials and others from input parameters
username = options[:username]
password = options[:password]
development_project = options[:development_project]
server = options[:server].to_s.empty? ? 'https://secure.gooddata.com' : options[:server]

# variables for standard output
counter_ok = 0
counter_error = 0
output = []
$result = []

# turn off logging for clear output
GoodData.logging_off

# connect to GoodData
client = GoodData.connect(login: username, password: password, server: server)

# connect to development GoodData project
development_project = client.projects(development_project)

# checking dashboards and tabs
development_project.dashboards.each do |dashboard|

  # checking dashboards name
  misspelled_words = check_misspelled(Spellchecker.check(dashboard.title.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|projectDashboardPage|' + dashboard.uri,
        :api => server + dashboard.uri,
        :title => '"' + misspelled_word[:error] + '"' +' in dashboards name '+ dashboard.title,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end

  # checking dashboards description
  misspelled_words = check_misspelled(Spellchecker.check(dashboard.summary.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '/#s=' + development_project.uri + '|projectDashboardPage|' + dashboard.uri,
        :api => server + dashboard.uri,
        :title => '"' + misspelled_word[:error] + '"' +' in dashboards description '+ dashboard.summary,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end

  dashboard.tabs.each do |tab|

    # checking tab name
    misspelled_words = check_misspelled(Spellchecker.check(tab.title.gsub('-', ' ').gsub('/', ' ').delete(',()')))
    misspelled_words.each do |misspelled_word|

      output.push(details = {
          :type => 'ERROR',
          :url => server + '/#s=' + development_project.uri + '|projectDashboardPage|' + dashboard.uri + '|' + tab.identifier,
          :api => server + dashboard.uri,
          :title => '"' + misspelled_word[:error] + '"' + ' in tab name '+ dashboard.title + ' - ' + tab.title,
          :description => 'Suggestion: ' + misspelled_word[:suggestions]
      })
      counter_error += 1
    end
  end
end

# checking metrics name
development_project.metrics.each do |metric|
  misspelled_words = check_misspelled(Spellchecker.check(metric.title.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|objectPage|' + metric.uri,
        :api => server + metric.uri,
        :title => '"' + misspelled_word[:error] + '"' + ' in metric name '+ metric.title,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end
end

# checking metrics description
development_project.metrics.each do |metric|
  misspelled_words = check_misspelled(Spellchecker.check(metric.summary.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|objectPage|' + metric.uri,
        :api => server + metric.uri,
        :title => '"' + misspelled_word[:error] + '"' + ' in description '+ metric.summary,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end
end

# checking reports name
development_project.reports.each do |report|
  misspelled_words = check_misspelled(Spellchecker.check(report.title.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + report.uri,
        :api => server + report.uri,
        :title => '"' + misspelled_word[:error] + '"' + ' in report name '+ report.title,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end
end

# checking reports description
development_project.reports.each do |report|
  misspelled_words = check_misspelled(Spellchecker.check(report.summary.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + report.uri,
        :api => server + report.uri,
        :title => '"' + misspelled_word[:error] + '"' + ' in report description '+ report.summary,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end
end

# checking facts name
development_project.facts.each do |fact|
  misspelled_words = check_misspelled(Spellchecker.check(fact.title.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + fact.uri,
        :api => server + fact.uri,
        :title => '"' + misspelled_word[:error] + '"' + ' in fact name '+ fact.title,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end
end

# checking facts description
development_project.facts.each do |fact|
  misspelled_words = check_misspelled(Spellchecker.check(fact.summary.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + fact.uri,
        :api => server + fact.uri,
        :title => '"' + misspelled_word[:error] + '"' + ' in fact description ' + fact.summary,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end
end

# checking attributes name
development_project.attributes.each do |attribute|
  misspelled_words = check_misspelled(Spellchecker.check(attribute.title.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + attribute.uri,
        :api => server + attribute.uri,
        :title => '"' + misspelled_word[:error] + '"' + ' in attribute ' + attribute.title,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end
end

# checking attributes description
development_project.attributes.each do |attribute|
  misspelled_words = check_misspelled(Spellchecker.check(attribute.summary.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + attribute.uri,
        :api => server + attribute.uri,
        :title => '"' + misspelled_word[:error] + '"' + ' in attribute description ' + attribute.summary,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end
end

# checking datasets name
development_project.datasets.each do |dataset|
  misspelled_words = check_misspelled(Spellchecker.check(dataset.title.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + dataset.uri,
        :api => server + dataset.uri,
        :title => '"' + misspelled_word[:error] + '"' + ' in dataset name '+ dataset.title,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end
end

# checking datasets description
development_project.datasets.each do |dataset|
  misspelled_words = check_misspelled(Spellchecker.check(dataset.summary.gsub('-', ' ').gsub('/', ' ').delete(',()')))
  misspelled_words.each do |misspelled_word|

    output.push(details = {
        :type => 'ERROR',
        :url => server + '#s=' + development_project.uri + '|analysisPage|head|' + dataset.uri,
        :api => server + dataset.uri,
        :title => '"' + misspelled_word[:error] + '"' + ' in dataset description '+ dataset.summary,
        :description => 'Suggestion: ' + misspelled_word[:suggestions]
    })
    counter_error += 1
  end
end

$result.push({:section => 'Spell Check name and description in dashboards, tabs, metrics, reports, facts, attributes and datasets', :OK => counter_ok, :INFO => 0, :ERROR => counter_error, :output => output})
puts $result.to_json

client.disconnect
