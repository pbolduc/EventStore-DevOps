# Install Event Store cluster on Virtual Machines

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpbolduc%2FEventStore-DevOps%2Fmaster%2Fazure-resource-manager%2FEventStoreCluster%2FTemplates%2FDeploymentTemplate.json#" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Create a multi-machine Event Store cluster on Windows or Ubuntu.  This template is heavily influenced by the [Elasticsearch cluster on Virtual Machines](https://github.com/Azure/azure-quickstart-templates/tree/master/elasticsearch) template sample on GitHub.

Parameters  | Default  | Description
------------- | ------------- | -------------
adminUsername |  | The operating system admin username used when provisioning virtual machines
adminPassword |  | The operating system admin password used when provisioning virtual machines
location | ResourceGroup | Location where resources will be provisioned.  A value of 'ResourceGroup' will deploy the resource to the same location of the resource group the resources are provisioned into
virtualNetworkName | esvnet | Virtual Network name
OS | windows | The operating system to install on the VM. Allowed values are: windows or ubuntu. (*ubuntu is not complete*)
jumpbox | No | Optionally add a virtual machine to the deployment which you can use to connect and manage virtual machines on the internal network
vmEventStoreNodeCount | 1 | Number of Event Store nodes to provision
vmSizeEventStoreNode | Standard_D2 | The VM size to deploy
vmEventStoreDataDiskSize | 4 | Size of each data disk attached to data nodes in (Gb). Each VM size will be provisioned with the maximum number of data disks to maximize the IOPS. In Windows, you can only pool disks that have 4GB of contiguous unallocated space.
esVersion | 3.3.0 | The Event Store version to install (*install is not complete*)



* a Storage Account for OS Disks
* an Availability Set
* a Virtual Network with a single subnet with 16 available addresses
* a Public IP address for each node
* a NIC for each node
* a VM for each node (A2)

TODO:
* add custom script extensions to provision and configure Event Store
