# Fetching admin password from AWS Secrets Manager
admin_pwd = shell_out!('aws secretsmanager get-secret-value --region us-east-2 --secret-id Splunk_Password | jq -r .SecretString').stdout.chomp 

# Fetching Region
region = shell_out!('curl -s http://169.254.169.254/latest/dynamic/instance-identity/document/ | jq -r .region').stdout.chomp 

# Fetching Deployer IP
deployer_ip = shell_out!("aws ec2 describe-instances --region #{region} --filters 'Name=tag:role,Values=DP' --query 'Reservations[].Instances[?State.Name==`running` || State.Name==`pending`].[PrivateIpAddress]' --output text")

# Splunk Home directory
splunk_install_dir = '/opt/splunk'

# Executing 'apt-get update'
execute "update-package" do
    command "sudo apt-get update"
    action :run
end

# Configuring SearchHead
execute "configure-searchhead" do
    command "#{splunk_install_dir}/bin/splunk edit cluster-config -mode searchhead -master_uri https://#{deployer_ip} :8089 -secret #{admin_pwd} -auth admin:#{admin_pwd}"
    action :run
end

# Restarting Splunk service
execute "restart-splunk" do
    command "sudo systemctl restart splunk"
    action :run
end

# Setting Splunk Hostname 
execute "set-hostname" do
    command "#{splunk_install_dir}/bin/splunk set servername searchhead -auth admin:#{admin_pwd}"
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
servers = localhost:localhost
    
[distributedSearch:dmc_group_cluster_master]
    
[distributedSearch:dmc_group_license_master]
    
[distributedSearch:dmc_group_indexer]
default = false
    
[distributedSearch:dmc_group_deployment_server]
    
[distributedSearch:dmc_group_kv_store]
    
[distributedSearch:dmc_group_shc_deployer]
EOH
end