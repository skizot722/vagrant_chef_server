log_level                :info
log_location             STDOUT
node_name                'knife-client-user'
client_key               '/home/slhunter/.chef/knife-client-user.pem'
validation_client_name   'chef-validator'
validation_key           '/etc/chef/validation.pem'
chef_server_url          'http://localhost:44000'
cache_type               'BasicFile'
cache_options( :path => '/home/slhunter/.chef/checksums' )
cookbook_path            ["#{ENV['HOME']}/chef-repository/cookbooks"]
