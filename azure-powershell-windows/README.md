I thought I would share the work I have done to automatically setup Event Store running on Azure VMs.  Right now, it only targets Windows hosts, but should be easily extended for Linux.  To extend for Linux, you would need to create a shell script to replace the PowerShell provisioning script shown in step #4.  I have observed it takes about 20 minutes until all the VMs are running with Event Store.

https://gist.github.com/pbolduc/f8ba49358a97e1e95332

Files:

* ProvisionEventStore.ps1  - creates Affinity Group, Storage Account, VMs and data disks for VMs
* EventStoreScriptExtensionProvisionFile.ps1 - Run automatically on the VM to install and configure Event Store to run as a service using NSSM

Features:

* Creates any number of VMs for your cluster. No validation to ensure the number is odd.  See -ClusterSize
* Creates a stripped data disk using as many data disks the VM will support based on the instance size. The user specifies total target disk size in GB
* Creates all VMs inside the same cloud service. VMs in the same cloud service can resolve the VM names to internal IP addresses
* Uses a virtual network so nodes can user internal addresses for communication
* Sets up all resources in one affinity group to ensure VMs and storage are close to each other in the data center
* Creates a random storage account name to avoid conflicts (uses the user supplied prefix)

on each VM created:

* Formats all the data disks into a single striped volume
* Installs Chocolatey
* Installs NSSM using Chocolatey
* Downloads Event Store 3.0.1 from http://download.geteventstore.com/binaries/EventStore-OSS-Win-v3.0.1.zip
* Determines the IP addresses of the other nodes and configures the gossip seeds in the configuration file
* Adds a service called 'EventStore' that will start automatically
* Logs are written to D:\Logs\eventstore\
* Data is stored to F:\Data\eventstore\
* Adds firewall rules to allow Event Store traffic
* Adds netsh urlacls for Event Store

How to use:

1. Manually create a virtual network so that your Event Store nodes can talk to each other on private IP addresses
2. Manually create a named subnet in your virtual network
3. Manually create a storage account and container to host the the custom script extension
4. Upload file EventStoreScriptExtensionProvisionFile.ps1 (found in the gist) to your custom script extension container
5. Install the Azure PowerShell Cmdlets and ensure they are working with your subscription (see: How to install and configure Azure PowerShell)
6. Login to your Azure account using Add-AzureAccount and/or 
7. Run ProvisionEventStore.ps1 with your desired parameters

Example Execution:

```
# Run Add-AzureAccount to get a authorization token

$VerbosePreference = 'Continue'

Write-Verbose "$(Get-Date -Format 'T') Starting Provision Environment"

. "$PSScriptRoot\ProvisionEventStore.ps1" `
    -ClusterSize 3 `
    -DataDiskSize 160 `
    -Location "West US" `
    -InstanceSize "Medium" `
    -username "admin-username" `
    -password "admin-password" `
    -ServiceName "cloud-service-name" `
    -VMName  "vm-name-prefix" `
    -ImageName "a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201502.01-en.us-127GB.vhd" `
    -AffinityGroup "affinity-group-name" `
    -TargetStorageAccountName "target-storage-account" `
    -AvailabilitySetName "availability-set-name" `
    -VNetName "virtual-network-name" `
    -VNetSubnetName "subnet-name" `
    -CustomScriptExtensionStorageAccountName "storage-account-name" `
    -CustomScriptExtensionStorageAccountKey 'storage-account-key' `
    -CustomScriptExtensionContainerName 'storage-account-container-name' `
    -CustomScriptExtensionProvisionFile 'EventStoreScriptExtensionProvisionFile.ps1'

Write-Verbose "$(Get-Date -Format 'T') Provision Complete"
```

Example output:
```
VERBOSE: 1:54:35 PM Starting Provision Environment
VERBOSE: 1:54:35 PM Ensuring Affinity Group 'EventStore' exists and is in 'West US' location.
VERBOSE: 1:54:35 PM - Begin Operation: Get-AzureAffinityGroup
VERBOSE: 1:54:36 PM - Completed Operation: Get-AzureAffinityGroup
VERBOSE: 1:54:36 PM - Begin Operation: Get-AzureStorageAccount
VERBOSE: 1:54:37 PM - Completed Operation: Get-AzureStorageAccount
WARNING: GeoReplicationEnabled property will be deprecated in a future release of Azure PowerShell. The value will be merged into the AccountType property.
VERBOSE: 1:54:37 PM - Begin Operation: New-AzureStorageAccount
VERBOSE: 1:55:09 PM - Completed Operation: New-AzureStorageAccount
VERBOSE: 1:55:09 PM Waiting for storage account eventstoreaeugnjsexgyefy to be available...
VERBOSE: 1:55:09 PM - Begin Operation: Get-AzureStorageAccount
VERBOSE: 1:55:10 PM - Completed Operation: Get-AzureStorageAccount
WARNING: GeoReplicationEnabled property will be deprecated in a future release of Azure PowerShell. The value will be merged into the AccountType property.
VERBOSE: 1:55:12 PM Creating Virtual Machines
VERBOSE: 1:55:12 PM - Begin Operation: New-AzureService
VERBOSE: 1:55:14 PM - Completed Operation: New-AzureService
VERBOSE: 1:55:14 PM - Begin Operation: Get-AzureRoleSize
VERBOSE: 1:55:14 PM - Completed Operation: Get-AzureRoleSize
VERBOSE: 1:55:28 PM - Begin Operation: New-AzureVM - Create Deployment with VM ES-demo-1
VERBOSE: 1:56:40 PM - Completed Operation: New-AzureVM - Create Deployment with VM ES-demo-1
VERBOSE: 1:56:40 PM - Begin Operation: New-AzureVM - Create VM ES-demo-2
VERBOSE: 1:57:47 PM - Completed Operation: New-AzureVM - Create VM ES-demo-2
VERBOSE: 1:57:47 PM - Begin Operation: New-AzureVM - Create VM ES-demo-3
VERBOSE: 1:58:53 PM - Completed Operation: New-AzureVM - Create VM ES-demo-3
VERBOSE: 1:58:53 PM Provision Complete
```