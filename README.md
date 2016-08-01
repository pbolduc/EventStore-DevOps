# EventStore DevOps

This project is used to setup an [Event Store](https://geteventstore.com/) cluster on Azure.  The preferred method is to use the azure resource manager approach.

* **azure-resource-manager** - Use Azure Resource Manager to create a cluster
* **vagrant-eventstore-cluster** - *not actively maintained* create a local Event Store cluster in vagrant and virtual box. Cloned from [seif/vagrant-eventstore-cluster](https://github.com/seif/vagrant-eventstore-cluster) and now references my fork of [eventstore-cookbook](https://github.com/pbolduc/eventstore-cookbook)
* **azure-powershell-Windows** - *depreicated* create an arbitrary sized Event Store cluster on Windows hosts on Windows Azure