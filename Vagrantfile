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

  # Chef server vm.
  config.vm.define :chef_server do |chef_server|
    # Uncomment the following if you don't want the chef server vm using the
    # default 512 MB  of memory.
    #config.vm.customize ["modifyvm", :id, "--memory", 256]

    # Hostname to set on the node
    chef_server.vm.host_name="chef-server"

    # Hostonly network interface, used for internode communication
    chef_server.vm.network :hostonly, "10.0.0.10"

    # Bootstrap this virtual machine using chef solo and the local cookbook.
    chef_server.vm.provision :chef_solo do |chef|
      chef.log_level = :debug
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "chef-server"
    end

    # Set up port forwards for host access to chef server.
    chef_server.vm.forward_port 4000, 44000
    chef_server.vm.forward_port 4040, 44040
  end

  # Chef client vm.
  config.vm.define :test_node do |test_node|
    # Hostname to set on the node
    test_node.vm.host_name="test-node"

    # Hostonly network interface, used for internode communication
    test_node.vm.network :hostonly, "10.0.0.11"

    # Use chef server to provision this test node.
    test_node.vm.provision :chef_client do |chef|
      # Config for chef server.
      chef.chef_server_url = "http://10.0.0.10:4000"
      chef.validation_key_path = "validation.pem"

      # Recipes for test_node application.
      chef.add_recipe("ruby")
    end
  end
end