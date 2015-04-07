# -*- mode: ruby -*-
# vi: set ft=ruby :

NODE_COUNT    = 3
BASE_IP       = "33.33.33"
IP_INCREMENT  = 10

seeds = []

(1..NODE_COUNT).each do |index|
  last_octet = index * IP_INCREMENT
  node_ip = "#{BASE_IP}.#{last_octet}"
  seeds << {'index' => index,
            'name' => "node#{index}",
            'ip' => node_ip}
end

Vagrant.configure("2") do |cluster|
  # Install latest chef on the client node, requires vagrant-omnibus plugin
  cluster.omnibus.chef_version = :latest

  # Configure caching, so that cache can be shared among nodes, minimising downloads. Requires vagrant-cachier plugin
  # Uncomment next line to enable cachier, seems to cause problems on windows
    cluster.cache.auto_detect = true

  # Enable berkshelf because it makes manages cookbooks much simpler. Required vagrant-berkshelf plugin
  cluster.berkshelf.enabled = true


  seeds.each do |seed|
    cluster.vm.define seed['name'] do |config|
      config.vm.box = "ubuntu/trusty64"
      config.vm.provider(:virtualbox) { |v| v.customize ["modifyvm", :id, "--memory", 1024] }

      config.vm.hostname = seed['name']
      config.vm.network :private_network, ip: seed['ip']

      # Provision using Chef.
      config.vm.provision :chef_solo do |chef|
        chef.json = {
          :eventstore => {
            :config => {
              :IntIp => seed['ip'],
              :ExtIp => seed['ip'],
              :IntHttpPort => 2112,
              :ExtHttpPort => 2113,
              :IntTcpPort => 1112,
              :ExtTcpPort => 1113,
              :ClusterSize => NODE_COUNT,
              :DiscoverViaDns => false,
              :GossipSeed => seeds.reject{|s| s['index'] == seed['index']}.map{|i| "#{i['ip']}:2112"}
            }
          }
        }
        chef.add_recipe "eventstore"
      end
    end
  end
end
