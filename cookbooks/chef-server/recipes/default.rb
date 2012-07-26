ENV['DEBIAN_FRONTEND'] = "noninteractive"

# Add the Opscode repository to the apt sources list.
bash "add-opscode-repo" do
  user "root"
  code <<-CODE
    echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
    sudo mkdir -p /etc/apt/trusted.gpg.d
    gpg --fetch-key http://apt.opscode.com/packages@opscode.com.gpg.key
    gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
  CODE
  not_if "sudo test -e /etc/apt/sources.list.d/opscode.list && grep 'deb http://apt.opscode.com' /etc/apt/sources.list.d/opscode.list"
end

# Now that the Opscode repo has been added, update apt.
execute "apt-update" do
  command "apt-get update"
  action :run
end

# Install the opscode keyring to keep repo key up-to-date.
package "opscode-keyring" do
  action :install
  options "-o Dpkg::Options::=\"--force-confnew\""
end

# Install the debcon-utils package, which is needed for non-interactive install
# of chef-server.
package "debconf-utils" do
  action :install
end

# Install expect package, as it's needed to configure knife non-interactively.
package "expect" do
  action :install
end

# Use debconf-set-selections to set question/answer pairs for non-interactive
# chef-server install.
bash "set-config-options-chef-packages" do
  user "root"
  code <<-CODE
    echo "chef-solr chef-solr/amqp_password password l33+s3cr3+" | debconf-set-selections
    echo "chef chef/chef_server_url string  http://localhost:4000" | debconf-set-selections
    echo "chef-server-webui chef-server-webui/admin_password password l33+s3cr3+" | debconf-set-selections
  CODE
end

# Install the chef client package.
package "chef" do
  action :install
end

# Install the chef-server package.
package "chef-server" do
  action :install
end

# Create chef directory for vagrant user.
directory "/home/vagrant/.chef" do
  owner "vagrant"
  group "vagrant"
  action :create
end

# Copy keys to shared folder so that it can be accessed by test node and host.
bash "cp-chef-pems" do
  user "root"
  code <<-CODE
    cp /etc/chef/validation.pem /home/vagrant/.chef/validation.pem
    cp /etc/chef/webui.pem /home/vagrant/.chef/webui.pem
  CODE
end

# Make sure everything inside the chef directory for the vagrant user is owned
# by the vagrant user.
execute "chown-home-chef" do
  user "root"
  command "chown -R vagrant /home/vagrant/.chef"
  action :run
end

# Create knife-expect.sh script for configuring knife.
cookbook_file "/tmp/knife-expect.sh" do
  source "knife-expect.sh"
  owner "vagrant"
  group "vagrant"
  mode 0700
end

# Configure knife using knife-expect expect script.
execute "configure-knife" do
  cwd "/home/vagrant"
  environment ({'HOME' => '/home/vagrant', 'USER' => "vagrant"})
  user "vagrant"
  command "/tmp/knife-expect.sh"
  not_if "test -e /home/vagrant/.chef/vagrant.pem", :user => 'vagrant'
end

# Create a new knife client account for use on the host.
execute "create-knife-client-user" do
  cwd "/home/vagrant"
  environment ({'HOME' => '/home/vagrant', 'USER' => "vagrant"})
  user "vagrant"
  command "knife client create knife-client-user -d -a -f /tmp/knife-client-user.pem"
  not_if "knife client show knife-client-user", :user => 'vagrant'
end

# Copy knife-client-user.pem to /vagrant after it's created, so that the host
# has access to it. This allows knife to be successfully configured on the host.
execute "copy-knife-client-key" do
  user "vagrant"
  command "cp /tmp/knife-client-user.pem /vagrant"
  not_if "test ! -e /tmp/knife-client-user.pem"
end

# Copy validation.pem to /vagrant after it's created, so that the test node
# has access to it.
execute "copy-validation-key" do
  user "root"
  command "cp /etc/chef/validation.pem /vagrant/"
  not_if "test -e /vagrant/validation.pem"
end
