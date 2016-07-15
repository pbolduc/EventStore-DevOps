#
# This script will create a stripped data disk with all available disks.
# Note: For disks to be added to a pool, they must be at least 4GB in size.
#
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\ps-output-createdisks.txt -append -noClobber

Write-Verbose 'Creating Storage Pool'

$storagePoolFriendlyName = 'LUN-0'
$virtualDiskFriendlyName = 'Datastore01'
$physicalDisks = Get-PhysicalDisk -CanPool $true
$numberOfColumns = $physicalDisks.Length

New-StoragePool -FriendlyName $storagePoolFriendlyName `
				-StorageSubSystemUniqueId (Get-StorageSubSystem -FriendlyName '*Space*').uniqueID `
				-PhysicalDisks $physicalDisks
 
Write-Verbose 'Creating Virtual Disk'
 
New-VirtualDisk -FriendlyName $virtualDiskFriendlyName `
				-StoragePoolFriendlyName $storagePoolFriendlyName `
				-UseMaximumSize `
				-NumberOfColumns $NumberOfColumns `
				-Interleave 65536 `
				-ProvisioningType Fixed `
				-ResiliencySettingName Simple

Start-Sleep -Seconds 20

Write-Verbose 'Initializing Disk'

Initialize-Disk -VirtualDisk (Get-VirtualDisk -FriendlyName $virtualDiskFriendlyName)

Start-Sleep -Seconds 20

$diskNumber = ((Get-VirtualDisk -FriendlyName $virtualDiskFriendlyName | Get-Disk).Number)

Write-Verbose 'Creating Partition'

New-Partition -DiskNumber $diskNumber `
		  -UseMaximumSize `
		  -DriveLetter F
 
Start-Sleep -Seconds 20

Write-Verbose 'Formatting Volume and Assigning Drive Letter'
 
Format-Volume -DriveLetter F `
		  -FileSystem NTFS `
		  -NewFileSystemLabel 'Data' `
		  -Confirm:$false `
		  -Force

Stop-Transcript