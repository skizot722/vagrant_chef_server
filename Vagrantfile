# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # Every Vagrant virtual environment requires a box to build off of.
  # Use this basebox image
  config.vm.box = "squeeze64"

  # If the basebox image is not yet cached on the local system source it from here
  config.vm.box_url = "http://dl.dropbox.com/u/937870/VMs/squeeze64.box"

  # Check for the correct version of virtualbox guest additions
  # when booting this machine
  config.vbguest.auto_update = true

  # Download the iso file from remote webserver
  config.vbguest.no_remote = false

  # We don't need much memory for either machine.
  #config.vm.customize ["modifyvm", :id, "--memory", 256]

  # Chef server vm.
  config.vm.define :chef_server do |chef_server|
    # Hostname to set on the node
    chef_server.vm.host_name="chef-server"

    # Hostonly network interface, used for internode communication
    chef_server.vm.network :hostonly, "10.0.0.10"

    chef_server.vm.provision :chef_solo do |chef|
      chef.log_level = :debug
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "chef-server"
    end

    chef_server.vm.forward_port 4000, 44000
    chef_server.vm.forward_port 4040, 44040
  end

  # Chef client vm.
  config.vm.define :bwmgr_test do |bwmgr|
    # Hostname to set on the node
    bwmgr.vm.host_name="bwmgr-test"

    # Hostonly network interface, used for internode communication
    bwmgr.vm.network :hostonly, "10.0.0.11"

    bwmgr.vm.provision :chef_client do |chef|
      # Config for chef server.
      chef.chef_server_url = "http://10.0.0.10:4000"
      chef.validation_key_path = "validation.pem"
#       chef.validation_client_name = "app-user"
#       chef.client_key_path = "app-user.pem"
#       chef.node_name = "bwmgr_test"

      # Recipes for bwmgr application.
      chef.add_recipe("ruby")
    end
  end
end