# Splunk Setup Role
name "SearchHead"
description "SearchHead Role"
run_list "recipe[splunk-cookbook::setup]", "recipe[splunk-cookbook::searchhead]"
