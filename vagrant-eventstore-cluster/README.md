# vagrant-eventstore-cluster


**Note**: cloned from [seif/vagrant-eventstore-cluster](https://github.com/seif/vagrant-eventstore-cluster)


Vagrant files to setup a local EventStore cluster using OpsCode Chef Cookbook

    > This is a work in progress.
    > Cluster and gossip seem to be setup correctly now, but having issues with Projections.

## Usage 

### Install Vagrant

Download and install [Vagrant](http://downloads.vagrantup.com/).

### Install Vagrant plugins

``` bash
vagrant plugin install vagrant-berkshelf
vagrant plugin install vagrant-omnibus
vagrant plugin install vagrant-cachier
```

### Clone this repository

``` bash
git clone https://github.com/seif/vagrant-eventstore-cluster.git
cd vagrant-eventstore-cluster
```

### Start the cluster

``` bash
vagrant up
```

Wait for all operations to complete, the cluster nodes should now be available at the address 33.33.33.10, 33.33.33.20 and 33.33.33.30

## Customising

### Vagrant configuration

There are some variables at the top of the file which you can use to customise the cluster:

* **NODE_COUNT:** The number of nodes in the cluster.
* **IP_INCREMENT:** How much to increment the ip of each node by.
* **BASE_IP:** The first 3 octects that will make up the ip, the last octet is made up of the IP_INCREMENT * node index.

### EventStore configuration

The [Event Store cookbook](http://community.opscode.com/cookbooks/eventstore) is used to provision the machines.

EventStore configuration parameters can be passed in by modifying the Vagrantfile and adding some keys/values to the eventstore/config hash. Any added keys will be put into the /etc/eventstore/config.json file.


