# GoodKit

Tools using GoodData Ruby SDK

## Prerequisites

1. Install [GoodData Ruby SDK](https://github.com/gooddata/gooddata-ruby) by executing "gem install gooddata" in your command line.  

## Use Cases

##1-prepare-release.rb 

Helps you to evaluate updated objects since the last release date in your Master project. You have to specify following parameters:

-m 'MASTER-PROJECT-ID'  
-u 'GoodData username'  
-p 'GoodData password'  
-d 'LAST-RELEASE-DATE'  

##2-release-changes.rb 

This exports all dashboards, reports and metrics that has been updated since last release date from the Master and Import them to all child projects specified in the project.csv file (see the -f parameter below)

### Parameters

-m 'MASTER-PROJECT-ID'  
-u 'GD-USERNAME'  
-p 'GD-PASSWORD'  
-d 'LAST-RELEASE-DATE'  
-f 'PATH-TO-FILE-WITH-CUSTOMER-PROJECT'  

The file(.csv) with customers project should follow the structure:

project-id, customer, attribute1, ...

Only list Project IDs is taken and all objects are released to all projects listed in the file.

##3-check-unfinished-objects.rb

Helps you to evaluate updated objects since the last release date in your Master project. Lists only objects that "needs to be finished" = missing description, unlisted or unlocked objects". You can use following parameters with the script:

-m 'MASTER-PROJECT-ID'  
-u 'GoodData username'  
-p 'GoodData password'  
-d 'LAST-RELEASE-DATE'  

##4-merge-models.rb 

**Supported only with pre-release candidate Ruby SDK**

This propagates LDM changes from master to all client Projects listed in the file specified as parameter. See available parameters below.

### Parameters

-m 'MASTER-PROJECT-ID'  
-u 'GD-USERNAME'  
-p 'GD-PASSWORD'  
-d 'LAST-RELEASE-DATE'  
-f 'PATH-TO-FILE-WITH-CUSTOMER-PROJECT' 


## Note:

You can select objects that won't be released by tagging them. You have to listed those tags in the script. See the _ignore_tags_ variable in both scripts ~ row #20.

## Example usage

ruby 1-prepare-release.rb -u 'username@company.com' -p 'password' -m 'my-master-project-id' -d '10 Apr 2015'

