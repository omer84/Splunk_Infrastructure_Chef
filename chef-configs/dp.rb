name "Deployer"
description "Deployer Role"
run_list "recipe[splunk-cookbook::setup]", "recipe[splunk-cookbook::deployer]"