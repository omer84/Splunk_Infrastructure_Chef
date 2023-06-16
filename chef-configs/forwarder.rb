# Executing 'apt-get update'
execute "update-package" do
    command "sudo apt-get update"
    action :run
end