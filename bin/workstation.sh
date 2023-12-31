#!/bin/bash

# Creating Hostname
hostname="chef-workstation"
echo "$hostname" >> $logfile

# Setting Hostname 
sudo hostname "$hostname"

# Installing Dependencies 
ebs_device="/dev/xvdf"
sudo apt-get install wget curl unzip software-properties-common gnupg2 -y
sudo apt-get update -y
sudo wget https://packages.chef.io/files/stable/chef-workstation/23.5.1040/ubuntu/20.04/chef-workstation_23.5.1040-1_amd64.deb
sudo dpkg -i chef-workstation_23.5.1040-1_amd64.deb
sudo apt-get install unzip -y
sudo apt-get install xfsprogs -y
sudo apt-get install jq -y
sudo apt install awscli -y
sudo apt-get update -y
sudo mkfs -t ext4 $ebs_device
splunkdir=/opt/splunk
logfile=/tmp/logs.txt
sudo touch $logfile

# Checking whether splunk home directory exists or not if not then creating it 
if [ -d $splunkdir ]; then
    echo "$splunkdir" exists
else
    sudo mkdir $splunkdir
    echo "dir created" >> $logfile
fi

sleep 10

# Mounting EBS volume to splunk home directory
sudo mount $ebs_device $splunkdir
mount_exitcode=$?
    if [ "$mount_exitcode" != "0" ]; then
        echo "Mount failed" >> $logfile
        echo $mount_exitcode >> $logfile
    fi

# Retrieving chef code from S3 bucket 
aws s3 cp s3://chef-code-repo/Demo-key.pem /root 
aws s3 cp s3://chef-code-repo/chef-starter.zip /root

sleep 5

# Unziping the chef-starter pack
unzip -q /root/chef-starter.zip -d /root
unzip_code=$?
echo "unzip code" >> $logfile
echo $unzip_code >> $logfile

mv /root/Demo-key.pem /root/chef-repo

# Getting Instance details
identity_doc=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document/)
availability_zone=$(echo "$identity_doc" | jq -r '.availabilityZone')
instance_id=$(echo "$identity_doc" | jq -r '.instanceId')
private_ip=$(echo "$identity_doc" | jq -r '.privateIp')
public_ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
account_id=$(echo "$identity_doc" | jq -r '.accountId')
region=$(echo "$identity_doc" | jq -r '.region')
ebs_tag_key="Snapshot"
ebs_tag_value="true"

# Getting tags from EC2 instance
tags=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$instance_id" --region="$region" | jq '.Tags[]')
echo "$tags" >> $logfile

# Getting the value of tag role
role=$(echo "$tags" | jq -r 'select(.Key == "role") .Value')
echo "$role" >> $logfile

# Creating Name tag
value="${role//_/-}-${instance_id}"

# Creating tag and attach it to EC2 instance
aws ec2 create-tags --resources "$instance_id" --region="$region" --tags "Key=Name,Value=$value"

# Checking whether tag is attached or not
if [ $? -eq 0 ]; then
    echo "Tag attached" >> $logfile
fi

# Retrieving the volume ids whose state is available
volume_ids=$(aws ec2 describe-volumes --region "$region" --filters Name=tag:"$ebs_tag_key",Values="$ebs_tag_value" Name=availability-zone,Values="$availability_zone" Name=status,Values=available | jq -r '.Volumes[].VolumeId')	
echo "$volume_ids"  >> $logfile	
if [ -n "$volume_ids" ]; then	
    break	
fi	

# Attaching the volume to the Instance (The volume will remain the same after instance gets reprovision)
for volume_id in $volume_ids; do
    aws ec2 attach-volume --region "$region" --volume-id "$volume_id" --instance-id "$instance_id" --device "$ebs_device"

    # Checking whether volume attached or not
    if [ $? -eq 0 ]; then
        echo "Volume attached" >> $logfile
        attached_volume=$volume_id
    fi
done

# Wait till the volume gets attached
state=$(aws ec2 describe-volumes --region "$region" --volume-ids "$attached_volume" | jq -r '.Volumes[].Attachments[].State')	
if [ "$state" == "attached" ]; then	
    echo "Volume attached success"  >> $logfile	
fi	
sleep 5	

# Checking whether the volume is already mounted or not if not the mounting it 
df -h | grep -i /opt/splunk
mount_code=$?

if [ "$mount_code" != "0" ]; then
    # Mounting the EBS volume to splunkdir
    sudo mount $ebs_device $splunkdir   
    mount_exitcode=$?
    if [ "$mount_exitcode" != "0" ]; then
      echo "Mount failed" >> $logfile
      echo $mount_exitcode >> $logfile
    fi
fi

# Retrieving EIPs that are not associate with any Instance
eips=$(aws ec2 describe-addresses --query "Addresses[?NetworkInterfaceId == null ].PublicIp" --region="$region" --output text)

# Attaching EIP to Instance
aws ec2 associate-address --region "$region" --public-ip "$eips" --instance-id "$instance_id"

# Getting the count of client node
client_count=$(aws ec2 describe-instances --region "$region" --filters "Name=tag:ChefEnv,Values=production" "Name=instance-state-name,Values=running,pending" --query 'length(Reservations[].Instances[])')
echo $client_count >> $logfile

cd /root/chef-repo
dir=$(pwd)
echo $dir >> $logfile

# Fetching the Private IP of the Deployer node
private_ip_deployer=$(aws ec2 describe-instances --region "$region" --filters "Name=tag:role,Values=DP" "Name=instance-state-name,Values=running,pending" --query 'Reservations[].Instances[].PrivateIpAddress' --output text)
echo $private_ip_deployer >> $logfile

# Fetching the Private IP of the Search Head node
private_ip_searchhead=$(aws ec2 describe-instances --region "$region" --filters "Name=tag:role,Values=SH" "Name=instance-state-name,Values=running,pending" --query 'Reservations[].Instances[].PrivateIpAddress' --output text)
echo $private_ip_searchhead >> $logfile

# Fetching the Private IP of the Forwarder node 
private_ip_forwarder=$(aws ec2 describe-instances --region "$region" --filters "Name=tag:role,Values=HF" "Name=instance-state-name,Values=running,pending" --query 'Reservations[].Instances[].PrivateIpAddress' --output text)
echo $private_ip_forwarder >> $logfile

# Fetching the Private IP of the Indexers node
private_ip_indexers=$(aws ec2 describe-instances --region "$region" --filters "Name=tag:role,Values=idx" "Name=instance-state-name,Values=running,pending" --query 'Reservations[].Instances[].PrivateIpAddress' --output text)
echo $private_ip_indexers >> $logfile

# Bootstrap the Deployer Node
sudo knife bootstrap $private_ip_deployer --ssh-user ubuntu --sudo -i Demo-key.pem -N Deployer --chef-license accept -y 2> /tmp/error.txt
code_dep=$?
echo "dep:$code_dep" >> $logfile

# Bootstrap the Search Head Node
sudo knife bootstrap $private_ip_searchhead --ssh-user ubuntu --sudo -i Demo-key.pem -N SearchHead --chef-license accept -y 2> /tmp/error.txt
code_sh=$?
echo "sh:$code_sh" >> $logfile

# Bootstrap the Forwarder Node
sudo knife bootstrap $private_ip_forwarder --ssh-user ubuntu --sudo -i Demo-key.pem -N Forwarder --chef-license accept -y 2> /tmp/error.txt
code_hf=$?
echo "hf:$code_hf" >> $logfile

# Bootstrap the Forwarder Node
for ip in $private_ip_indexers; do
    sudo knife bootstrap $private_ip_indexers --ssh-user ubuntu --sudo -i Demo-key.pem -N Indexer-$ip --chef-license accept -y 2> /tmp/error.txt
done

# Generating Splunk Cookbook & recipes
cd /root/chef-repo/cookbooks
chef generate cookbook splunk-cookbook --chef-license accept
cd /root/chef-repo/cookbooks/splunk-cookbook/recipes/
aws s3 sync s3://chef-code-repo/chef-configs/ . 
mv dp.rb hf.rb idx.rb set.rb sh.rb /root/chef-repo/roles
cd /root/chef-repo/cookbooks
sudo knife cookbook upload splunk-cookbook
cd /root/chef-repo/
sudo knife role from file roles/dp.rb
sudo knife role from file roles/hf.rb
sudo knife role from file roles/idx.rb
sudo knife role from file roles/set.rb
sudo knife role from file roles/sh.rb
sudo knife node run_list set Deployer "role[Deployer]"
sudo knife node run_list set SearchHead "role[SearchHead]"
sudo knife node run_list set Indexer-$ip "role[Indexer]"
sudo knife node run_list set Forwarder "role[Forwarder]"