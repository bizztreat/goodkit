# GoodKit

Toolkit that helps you to automate specific tasks in GoodData. It covers two main areas:

- Project Lifecycle Management (i.e. checking which reports has been added to the new version of the project or releasing those changes to the new version)  
- Testing (specific checks that helps you to automate tasks like "all metrics have version tags" etc.)  


## Prerequisites

1. Ruby installed on your local environment 
2. Install [GoodData Ruby SDK](https://github.com/gooddata/gooddata-ruby) by executing "gem install gooddata" in your command line.  
3. Admin access to GoodData projects that you want to use with this tool

## Example usage

1. Open your terminal and run following command:

ruby 1-prepare-release.rb -u 'username@company.com' -p 'password' -m 'my-master-project-id' -d '10 Apr 2015'

2. See the output.

# Use Cases

## Lifecycle

##1-prepare-release.rb 

Helps you to evaluate updated objects since the last release date in your Master project. You have to specify following parameters:

-m 'MASTER-PROJECT-ID'  
-u 'GoodData username'  
-p 'GoodData password'  
-d 'LAST-RELEASE-DATE'  
-h 'hostname for whitelabeled projects'

##2-release-changes.rb

**WARNING:** Migth brake your projects. Run only on project you are sure this can be used. 

This exports all dashboards, reports and metrics that has been updated since last release date from the Master and Import them to all child projects specified in the project.csv file (see the -f parameter below)

### Parameters

-m 'MASTER-PROJECT-ID'  
-u 'GD-USERNAME'  
-p 'GD-PASSWORD'  
-d 'LAST-RELEASE-DATE'  
-f 'PATH-TO-FILE-WITH-CUSTOMER-PROJECT'
-h 'hostname for whitelabeled projects'  

The file(.csv) with customers project should follow the structure:

project-id, customer, attribute1, ...

Only list Project IDs is taken and all objects are released to all projects listed in the file.

##3-check-unfinished-objects.rb

Helps you to evaluate updated objects since the last release date in your Master project. Lists only objects that "needs to be finished" = missing description, unlisted or unlocked objects". You can use following parameters with the script:

-m 'MASTER-PROJECT-ID'  
-u 'GoodData username'  
-p 'GoodData password'  
-d 'LAST-RELEASE-DATE' 
-h 'HOSTNAME-for-whitelabeled-projects' 

##4-merge-models.rb 

**WARNING:** Migth brake your projects. Run only on project you are sure this can be used.

This propagates LDM changes from master to all client Projects listed in the file specified as parameter. See available parameters below.

### Parameters

-m 'MASTER-PROJECT-ID'  
-u 'GD-USERNAME'  
-p 'GD-PASSWORD'  
-d 'LAST-RELEASE-DATE'  
-f 'PATH-TO-FILE-WITH-CUSTOMER-PROJECT' 
-h 'HOSTNAME-for-whitelabeled-projects'

### Note:

You can select objects that won't be released by tagging them. You have to listed those tags in the script. See the _ignore_tags_ variable in both scripts ~ row #20.

##21-merge-models-test.rb

This is testing the possibility of merging two models. Doesn't brake anything, just do the test and print results.

### Parameters

-d 'DEVEL-PROJECT-ID'
-s 'START-PROJECT'
-u 'GD-USERNAME'
-p 'GD-PASSWORD'
-f 'PATH-TO-FILE-WITH-CUSTOMER-PROJECT'
-h 'HOSTNAME-for-whitelabeled-projects'


## Testing

Following scripts provide you with several tasks that make your life easier when testing new version of the Analytical app / Project.


### Parameters  

Following parameters can be used to run it successfully. `username`,`password` and `devel-project-id` is always mandatory, `start-project-id` is mandatory only for scripts that compare last version with the new version which is not always necessary. See available parameters:

-d 'DEVEL-PROJECT-ID'  
-s 'START-PROJECT-ID'  
-u 'GD-USERNAME'  
-p 'GD-PASSWORD'
-h 'hostname for whitelabeled projects'
  

###Use Cases

###5-tests-aggregations.rb

This computes all available aggregations of all facts in Devel project and compare results with Start project. You provide credentials to GD and project id for projects you want to compare.

Returns list of aggregations and result: **CORRECT** / **NOT MATCHED**

###6-test-report-results.rb

Compares same reports accross Devel and Start project and gives you overview of the results.

###7-check-missing-metrics-reports.rb

Gives you list of missing metrics and reports comparing Devel and Start projects.

###8-check-datasets-empty.rb

Prints out datasets that are empty for given project.

###9-check-version-tags.rb

Checks if all metrics and reports have version tags. Prints out objects without the tag.

###10-check-data-from-yesterday.rb

- Not released yet  
Check if there is a data from yesterday. Prints `OK` / `WRONG` status

###11-preview-checks.rb

This checks if all:

- Preview Reports are in Preview folder and used only on Preview Dashboards   
- Metrics tagged "preview" are used only in Preview Reports  

Output: Links to objects that have wrong setup. 

###12-check-metrics-def-change.rb

Checks if there was some change in metric definition (not metadata but expression itself) accross Devel and Start project. Prints out list of metrics that have been changed.

###13-check-reports-computable.rb

Checks if all reports are computable and gives you links to non computable reports as output.


###14-check-ga-code.rb

Checks if all dashboards contains Google Analytics tracking code. Prints link to dashboard tabs that don't have the tracking code embedded.

###15-check-not-used-objects.rb

Prints out all attributes and facts that are not used in any metric or report. Prints out links to 

###16-check-atribute-values.rb
Checks if atribute is not missing any value and there are no extra values as well.

This script has to parts. To switch between these two parts use parameter GENERATE -g "true/false" 

1. - the first part is used to generate JSON file containing values of attributes -g "true"

2. - the second part checks the values from the JSON file -g "false"

To select the group of checked attributes use the parameter -a "Attribute1,Attribute2" which is used as a list of attributes. 


