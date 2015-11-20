# Install Event Store cluster on Virtual Machines

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpbolduc%2FEventStore-DevOps%2Fmaster%2Fazure-resource-manager%2FEventStoreCluster%2FTemplates%2FDeploymentTemplate.json#" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Create a multi-machine Event Store cluster on Windows

* a Storage Account for OS Disks
* an Availability Set
* a Virtual Network with a single subnet with 16 available addresses
* a Public IP address for each node
* a NIC for each node
* a VM for each node (A2)

TODO:
* add custom script extensions to provision and configure Event Store


https://raw.githubusercontent.com/pbolduc/EventStore-DevOps/arm/azure-resource-manager/EventStoreCluster/Templates/DeploymentTemplate.json

https://raw.githubusercontent.com/pbolduc/EventStore-DevOps/arm/azure-resource-manager/EventStoreCluster/Templates/DeploymentTemplate.json#