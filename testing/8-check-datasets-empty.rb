require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    
end.parse!

#username = ''
#password = ''
username = options[:username]
password = options[:password]

#start = options[:start]
devel = options[:devel]
#start = 'x1c6gsmxhr84usnhww03s6ecx3625279'
#devel = 't3m4hv0v5vrysctjqax88t2q2346t6vd'
#empty = 'iko3rc16lh5te1qe94v1ocl95t0lwez1'

#testing master project ID = y672cuxov5x6swn64tlaz5jwcrez0wid

puts 'Connecting to GoodData...'
puts 'Printing out empty datasets:'

GoodData.with_connection(username, password) do |client|
   
   GoodData.with_project(devel) do |project|
           blueprint = project.blueprint
           blueprint.datasets.each do |dataset|
               count = dataset.count(project)
               if (count.to_i < 1) then puts dataset.title end
           end
       end
   
end

puts 'Disconnecting...'
GoodData.disconnect
