# Install Event Store cluster on Virtual Machines

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpbolduc%2FEventStore-DevOps%2Fmaster%2Fazure-resource-manager%2FEventStoreCluster%2FTemplates%2Fazuredeploy.json#" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Create a multi-machine Event Store cluster on Windows (Ubuntu is not complete).  This template is heavily influenced by the [Elasticsearch cluster on Virtual Machines](https://github.com/Azure/azure-quickstart-templates/tree/master/elasticsearch) template sample on GitHub.

Parameters  | Default  | Description
------------- | ------------- | -------------
adminUsername |  | The operating system admin username used when provisioning virtual machines
adminPassword |  | The operating system admin password used when provisioning virtual machines
location | ResourceGroup | Location where resources will be provisioned.  A value of 'ResourceGroup' will deploy the resource to the same location of the resource group the resources are provisioned into
virtualNetworkName | es-vnet | Virtual Network name
OS | windows | The operating system to install on the VM. Allowed values are: windows or ubuntu. (*ubuntu is not complete*)
jumpbox | No | Optionally add a virtual machine to the deployment which you can use to connect and manage virtual machines on the internal network
vmEventStoreNodeCount | 1 | Number of Event Store nodes to provision. The number must be odd. The template limits this to 9.
vmSizeEventStoreNode | Standard_D2 | The VM size to deploy
vmEventStoreDataDiskSize | 4 | Size of each data disk attached to data nodes in (Gb). Each VM size will be provisioned with the maximum number of data disks to maximize the IOPS. In Windows, you can only pool disks that have at least 4GB of contiguous unallocated space.  Setting this less than 4 will prevent striping of data disks and the installation will fail.
esVersion | 3.8.1 | The Event Store version to install
githubAccount | pbolduc | The github parameters allow changing the template root URL.  This allows customization of the source location install scripts that are uploaded to azure for provisioning. 
githubProject | EventStore-DevOps |
githubBranch | master |


* a Storage Account for OS Disks
* one or more storage accounts for data disks
* each VM will have multiple data disks striped together for higher IOPS (based on the maximum number of data disks allowed for VM size)
* an Availability Set
* a Virtual Network with a single subnet with 16 available addresses
* a Network Security Group
* a Public IP address for each node
* a NIC for each node
* a VM for each node

## Network Security Group configuration

The network security is setup in [shared-resources.json](EventStoreCluster/Templates/shared-resources.json)

* Allow Inbound TCP on port 80
* Allow Inbound TCP on port 1113
* Allow Inbound TCP on port 2113
