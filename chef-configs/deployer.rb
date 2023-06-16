# Fetching admin password
admin_pwd = shell_out!('aws secretsmanager get-secret-value --region us-east-2 --secret-id Splunk_Password | jq -r .SecretString').stdout.chomp 

# Splunk Home directory
splunk_install_dir = '/opt/splunk'

# Executing 'apt-get update'
execute "update-package" do
    command "sudo apt-get update"
    action :run
end

# Configure Deployer
execute "configure-deployer" do
    command "#{splunk_install_dir}/bin/splunk edit cluster-config -mode master -replication_factor 3 -search_factor 2 -secret #{admin_pwd} -auth admin:#{admin_pwd}"
    action :run
end

# Restarting Splunk service
execute "restart-splunk" do
    command "sudo systemctl restart splunk"
    action :run
end

# Setting Splunk Hostname 
execute "set-hostname" do
    command "#{splunk_install_dir}/bin/splunk set servername deployer -auth admin:#{admin_pwd}"
    action :run
end

# Restarting Splunk service
execute "restart-splunk" do
    command "sudo systemctl restart splunk"
    action :run
end

# Changing server role to deployer, cluster master & license master
file "#{splunk_install_dir}/etc/system/local/distsearch.conf" do
    content <<-EOH
[distributedSearch:dmc_group_search_head]

[distributedSearch:dmc_group_cluster_master]
servers = localhost:localhost
    
[distributedSearch:dmc_group_license_master]
servers = localhost:localhost
    
[distributedSearch:dmc_group_indexer]
default = false
    
[distributedSearch:dmc_group_deployment_server]
servers = localhost:localhost
    
[distributedSearch:dmc_group_kv_store]
    
[distributedSearch:dmc_group_shc_deployer]
EOH
end

