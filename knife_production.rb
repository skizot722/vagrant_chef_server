log_level                :info
log_location             STDOUT
node_name                'slhunter'
client_key               '/home/slhunter/.chef/slhunter.pem'
validation_client_name   'chef-validator'
validation_key           '/etc/chef/validation.pem'
chef_server_url          'http://chef.ccisystems.com:4000'
cache_type               'BasicFile'
cache_options( :path => '/home/slhunter/.chef/checksums' )
cookbook_path            ["#{ENV['HOME']}/chef-repository/cookbooks"]
