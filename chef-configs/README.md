# Chef Configuration files

* These are the chef configuration files for installing Splunk and configuring the Deployer, Search Head & Indexer.

* In order to set up the cluster we need to run the below command on the client nodes:

  ```chef-client```
  
* However, the chef-client will automatically run every 1 minute on the chef clients and pull the latest catalog from the master node.

![chef](https://github.com/DhruvinSoni30/Splunk_Infrastructure_Chef/blob/main/images/chef.jpeg)
