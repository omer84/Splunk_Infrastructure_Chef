# Fetching admin password
admin_pwd = shell_out!('aws secretsmanager get-secret-value --region us-east-2 --secret-id Splunk_Password | jq -r .SecretString').stdout.chomp 

# Specify URL of the Splunk tar package
splunk_url = "https://download.splunk.com/products/splunk/releases/9.0.4.1/linux/splunk-9.0.4.1-419ad9369127-Linux-x86_64.tgz"

# Define the target directory for Splunk installation
splunk_install_dir = '/opt/splunk'

# Download and extract the Splunk tar package
remote_file "splunk-9.0.4.1-419ad9369127-Linux-x86_64.tgz" do
    source splunk_url
    action :create
  end

execute "extract_splunk" do
    command "tar -xzf splunk-9.0.4.1-419ad9369127-Linux-x86_64.tgz -C #{splunk_install_dir} --strip-components=1"
    action :run
    not_if { ::File.exist?("#{splunk_install_dir}/bin/splunk") }
end

# Start the Splunk service
execute "start_splunk" do
    command "#{splunk_install_dir}/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd #{admin_pwd}"
    action :run
    not_if "#{splunk_install_dir}/bin/splunk status | grep 'splunkd is running'"
  end