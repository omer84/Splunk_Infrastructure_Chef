name "Indexer"
description "Indexer Role"
run_list "recipe[splunk-cookbook::setup]", "recipe[splunk-cookbook::indexer]"
