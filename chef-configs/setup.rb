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

# Stopping Splunk Service
execute "stop_splunk" do
    command "#{splunk_install_dir}/bin/splunk stop"
    action :run
end

# Configuring Splunk service to manage it with systemctl
file '/etc/systemd/system/splunk.service' do
    content <<-EOH
    [Unit]
    Description=Splunk
    After=network.target

    [Service]
    ExecStart=/opt/splunk/bin/splunk start
    Type=forking
    User=root
    Group=root
    Restart=on-failure
    TimeoutSec=300

    [Install]
    WantedBy=multi-user.target
    EOH
end

# Reloading Daemon
execute "reload-daemon" do
    command "sudo systemctl daemon-reload"
    action :run
end

# Enabling Splunk service
execute "enable-splunk" do
    command "sudo systemctl enable splunk"
    action :run
end

# Starting Splunk service
execute "start-splunk" do
    command "sudo systemctl start splunk"
    action :run
end