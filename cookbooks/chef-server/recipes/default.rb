ENV['DEBIAN_FRONTEND'] = "noninteractive"

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

execute "apt-update" do
  command "apt-get update"
  action :run
end

package "opscode-keyring" do
  action :install
  options "-o Dpkg::Options::=\"--force-confnew\""
end

package "debconf-utils" do
  action :install
end

package "expect" do
  action :install
end

bash "set-config-options-chef-packages" do
  user "root"
  code <<-CODE
    echo "chef-solr chef-solr/amqp_password password l33+s3cr3+" | debconf-set-selections
    echo "chef chef/chef_server_url string  http://localhost:4000" | debconf-set-selections
    echo "chef-server-webui chef-server-webui/admin_password password l33+s3cr3+" | debconf-set-selections
  CODE
end

package "chef" do
  action :install
end

package "chef-server" do
  action :install
end

directory "/home/vagrant/.chef" do
  owner "vagrant"
  group "vagrant"
  action :create
end

bash "cp-chef-pems" do
  user "root"
  code <<-CODE
    cp /etc/chef/validation.pem /home/vagrant/.chef/validation.pem
    cp /etc/chef/webui.pem /home/vagrant/.chef/webui.pem
  CODE
end

execute "chown-home-chef" do
  user "root"
  command "chown -R vagrant /home/vagrant/.chef"
  action :run
end

cookbook_file "/tmp/knife-expect.sh" do
  source "knife-expect.sh"
  owner "vagrant"
  group "vagrant"
  mode 0700
end

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

# Create a new app user account for use on the application vm.
execute "create-app-chef-client-user" do
  cwd "/home/vagrant"
  environment ({'HOME' => '/home/vagrant', 'USER' => "vagrant"})
  user "vagrant"
  command "knife client create app-user -d -a -f /tmp/app-user.pem"
  not_if "knife client show app-user", :user => 'vagrant'
end

# Copy knife-client-user.pem to /vagrant after it's created, so that the host
# has access to it. This allows knife to be successfully configured on the host.
execute "copy-knife-client-key" do
  user "vagrant"
  command "cp /tmp/knife-client-user.pem /vagrant"
  not_if "test ! -e /tmp/knife-client-user.pem"
end

# Copy app-user.pem to /vagrant after it's created, so that the application vm
# has access to it. This allows chef-client to authenticate successfully on
# the application vm.
execute "copy-app-user-key" do
  user "vagrant"
  command "cp /tmp/app-user.pem /vagrant"
  not_if "test ! -e /tmp/app-user.pem"
end
