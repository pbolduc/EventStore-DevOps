# ProvisionEventStore.ps1

<#
.SYNOPSIS
.DESCRIPTION
.EXAMPLE
#>

# http://azure.microsoft.com/en-us/documentation/articles/install-configure-powershell/
# Add-AzureAccount

param
(
    [Int]$ClusterSize,
    [Int]$DataDiskSize = 0,
    [String]$Location,
    [String]$InstanceSize,
    [String]$username,
    [String]$password,
    [String]$ServiceName,
    [String]$VMName,
    [String]$ImageName,
    [String]$AffinityGroup,
    [String]$TargetStorageAccountName,
    [Int]$MaxDisksPerStorageAccount = 40,
    [Int]$MaxDataDisksPerVirtualMachine = 0,
    [String]$AvailabilitySetName,
    [String]$VNetName,
    [String]$VNetSubnetName,
    [String]$CustomScriptExtensionStorageAccountName,
    [String]$CustomScriptExtensionStorageAccountKey,
    [String]$CustomScriptExtensionContainerName,
    [String]$CustomScriptExtensionProvisionFile
)

function Get-RandomStorageAccountName {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $prefix,
        [ValidateRange(3,24)] 
        [Int]
        $maxLength = 24
    )

    $name = $prefix.ToLower()
    while ($name.Length -lt 24) {
        $name = $name + [char](Get-Random -Minimum 97 -Maximum 122)
    }
    return $name
}

function Ensure-AzureAffinityGroup {
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $name, 
        [Parameter(Mandatory = $true)]
        [string]$location
    ) 

    $affinityGroup = Get-AzureAffinityGroup -Name $name -ErrorAction SilentlyContinue
    if ($affinityGroup -eq $null) {
        New-AzureAffinityGroup -Location $location -Name $name | Out-Null
    } elseif ($affinityGroup.Location -ne $location) {
        $actualLocation = $affinityGroup.Location
        Write-Error "Affinity Group '$name' exists, but is not in location '$location'. It is in location '$actualLocation'."
    }
}

function Ensure-StorageAccount() {
    if ((Get-AzureStorageAccount -StorageAccountName $TargetStorageAccountName -ErrorAction SilentlyContinue) -eq $null) {

        $storageAccountName = Get-RandomStorageAccountName($TargetStorageAccountName)
        New-AzureStorageAccount -AffinityGroup $AffinityGroup -StorageAccountName $storageAccountName -Type Standard_LRS | Out-Null

        # Wait for the storage account to be available so we can use it
        Write-Verbose "$(Get-Date -Format 'T') Waiting for storage account $storageAccountName to be available..."
        while ((Get-AzureStorageAccount -StorageAccountName $storageAccountName).StatusOfPrimary -ne "Available") {
            Start-Sleep -Seconds 1
        }
        return $storageAccountName
    } else {
        return $TargetStorageAccountName
    }
}

function Create-EventStoreNodes {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $StorageAccountName
    )
    <# Subscription Limits - http://azure.microsoft.com/en-us/documentation/articles/azure-subscription-service-limits/

                                                                         Default     Max limit
        Cores                                                                 20        10,000
        Storage accounts per subscription -                                  100           100
        
        Max 8 KB IOPS per persistent disk (Basic Tier)                       300
        Max 8 KB IOPS per persistent disk (Standard Tier)                    500
        Total Request Rate (assuming 1KB object size) per storage account 20,000
        Target Throughput for Single Blob                                 Up to 60 MB per second, or up to 500 requests per second
    #>

    # create the cloud service first so that it will be ready when the VM are created below
    New-AzureService -ServiceName $ServiceName -AffinityGroup $AffinityGroup | Out-Null

    $vms = @()

    $numberOfDataDisks = (Get-AzureRoleSize -InstanceSize $InstanceSize).MaxDataDiskCount
    
    # if we are limiting the total data disks
    if ($MaxDataDisksPerVirtualMachine -ge 1) {
        $numberOfDataDisks = [System.Math]::Min($numberOfDataDisks,$MaxDataDisksPerVirtualMachine)
    }
    
    $totalDiskCount = $ClusterSize * ($numberOfDataDisks+1) # OS Disk + N data disks $MaxDiskPerStorageAccount

    if ($totalDiskCount -ge 40) {
        Write-Warning "You may have too many disks per storage account. Your performance may degrade. See http://blogs.msdn.com/b/mast/archive/2014/10/14/configuring-azure-virtual-machines-for-optimal-storage-performance.aspx"
    }

    for ($node=1;$node -le $ClusterSize;$node++) {
        $name = $VMName + "-" + $node

        $vm = New-AzureVMConfig -ImageName $ImageName -InstanceSize $InstanceSize -Name $name -AvailabilitySetName $AvailabilitySetName
        $vm = $vm | Set-AzureSubnet -SubnetNames $VNetSubnetName
        
        $isWindows = $true
        if ($isWindows) {
	        $vm = $vm | Add-AzureProvisioningConfig -AdminUsername $username -Password $password -Windows
        } else {
	        $vm = $vm | Add-AzureProvisioningConfig -LinuxUser $username -Password $password -Linux
        }

        if ($true) {
            $StandardTcpPort = 1113
            $StandardHttpPort = 2113

            $ExtTcpPort = $StandardTcpPort + ($node - 1) * 100
            $ExtHttpPort = $StandardHttpPort + ($node - 1) * 100

            # http://michaelwasham.com/windows-azure-powershell-reference-guide/configuring-disks-endpoints-vms-powershell/
            $vm = $vm | Add-AzureEndpoint -Name 'EventStoreTcp' -LocalPort $ExtTcpPort -PublicPort $ExtTcpPort -Protocol Tcp
            $vm = $vm | Add-AzureEndpoint -Name 'EventStoreHttp' -LocalPort $ExtHttpPort -PublicPort $ExtHttpPort -Protocol Tcp
        }
            
        $vm = $vm | Set-AzureVMCustomScriptExtension `
                       -StorageAccountName $CustomScriptExtensionStorageAccountName `
                       -StorageAccountKey $CustomScriptExtensionStorageAccountKey `
                       -ContainerName $CustomScriptExtensionContainerName `
                       -FileName $CustomScriptExtensionProvisionFile `
                       -Run $CustomScriptExtensionProvisionFile `
                       -Argument "-clusterSize $ClusterSize -VMName $VMName -nodeNumber $node -ExtTcpPort $ExtTcpPort -ExtHttpPort $ExtHttpPort"

        # Attach the maximum data disks allowed for the virtual machine size
        if ($DataDiskSize -gt 0) {
            
            $minSizeInGB = 4 # min size for each disk to be stripped: All disks must be at least 4 GB.
            $sizeInGB = [int][System.Math]::Max([System.Math]::Ceiling($DataDiskSize / $numberOfDataDisks), $minSizeInGB)

            for ($index = 0; $index -lt $numberOfDataDisks; $index++) { 
                $label = "Data disk " + $index
                # The maximum number of data disks that may simultaneously use read caching is 4.
                $vm = $vm | Add-AzureDataDisk -CreateNew -DiskSizeInGB $sizeInGB -DiskLabel $label -LUN $index -HostCaching None
            }
        }

        $vms += $vm
    }
    
    # create all of the VMs
    New-AzureVM -ServiceName $ServiceName -VNetName $VNetName -VMs $vms | Out-Null
}

Write-Verbose "$(Get-Date -Format 'T') Ensuring Affinity Group '$AffinityGroup' exists and is in '$Location' location."
Ensure-AzureAffinityGroup $AffinityGroup $Location
$storageAccountName = Ensure-StorageAccount

$SubscriptionName = (Get-AzureSubscription).SubscriptionName 
Set-AzureSubscription -SubscriptionName $SubscriptionName -CurrentStorageAccount $storageAccountName

Write-Verbose "$(Get-Date -Format 'T') Creating Virtual Machines"
Create-EventStoreNodes -StorageAccountName $storageAccountName