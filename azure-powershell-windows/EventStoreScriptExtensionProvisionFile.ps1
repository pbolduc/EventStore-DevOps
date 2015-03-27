param (
    [Int]
    $clusterSize,
    [string]
    $VMName,
    [Int]
    $nodeNumber,
    [Int]
    $IntIp,
    [Int]
    $ExtIp,
    [Int]
    $IntTcpPort = 1112,
    [Int]
    $IntHttpPort = 2112,
    [Int]
    $ExtTcpPort = 1113,
    [Int]
    $ExtHttpPort = 2113
)


function Extract-ZipFile($file, $destination)
{
    if (![System.IO.Directory]::Exists($destination)) {
        [System.IO.Directory]::CreateDirectory($destination)
    }
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item)
    }
}

function Install-Chocolatey($InstallToPath) {
    $env:ChocolateyInstall = $InstallToPath
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

function Download-EventStore($DownloadUrl, $SaveToPath) {
    $client = new-object System.Net.WebClient
    $client.DownloadFile($DownloadUrl, $SaveToPath)
}

function Format-DataDisks() {
    $Interleave = 65536  # is this the best value for EventStore?
    $uninitializedDisks = Get-PhysicalDisk -CanPool $true
    
    $poolDisks = $uninitializedDisks
    $numberOfDisksPerPool = $poolDisks.Length
        
    $poolName = "Data Storage Pool"
    $newPool = New-StoragePool -FriendlyName $poolName -StorageSubSystemFriendlyName "Storage Spaces*" -PhysicalDisks $poolDisks
        
    $virtualDiskJob = New-VirtualDisk -StoragePoolFriendlyName $poolName  -FriendlyName $poolName -ResiliencySettingName Simple -ProvisioningType Fixed -Interleave $Interleave `
        -NumberOfDataCopies 1 -NumberOfColumns $numberOfDisksPerPool -UseMaximumSize -AsJob
    
    Receive-Job -Job $virtualDiskJobs -Wait
    Wait-Job -Job $virtualDiskJobs                        
    Remove-Job -Job $virtualDiskJobs
    
    # Initialize and format the virtual disks on the pools
    $formatted = Get-VirtualDisk | Initialize-Disk -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false

    # Create the data directory
    $formatted | ForEach-Object {
        # Get current drive letter.
        $downloadDriveLetter = $_.DriveLetter
        
        # Create the data directory
        $dataDirectory = "$($downloadDriveLetter):\Data"
        
        New-Item $dataDirectory -Type directory -Force | Out-Null
    }
    
    # Dive time to the storage service to pick up the changes
    Start-Sleep -Seconds 60
}

function New-EventStoreConfigFile() {

    $seeds = @()
    for ($n = 1; $n -le $clusterSize; $n++) {
        $nodeName = $VMName + "-" + $n
        if ($nodeName -ne $env:COMPUTERNAME) {
            do {
                # the other nodes may not be running yet, wait for them to return an ip address
                $ip = (Resolve-DnsName $nodeName -Type A -ErrorAction SilentlyContinue).IPAddress
            } while ($ip -eq $null)
            
            # 
            $seeds += "'" + $ip + ":" + $IntHttpPort + "'"
        }
    }

    $gossipSeed = $seeds -join ','

    # this is a bit of a hack that depends on the BGInfo plugin. Is there a better way to determine this?
    #$publicIp = PS C:\Users\eventstore> (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Azure\BGInfo").PublicIp
    
    $configFile = "C:\EventStore\EventStore-Config.yaml"
    $ipAddress = (Resolve-DnsName $env:COMPUTERNAME -Type A).IPAddress

    $IntIp = $ipAddress
    $ExtIp = $ipAddress

    "# EventStore configuration file. Created at: $(Get-Date -Format 'u')" | Out-File -FilePath $configFile
    "Db: F:\Data\eventstore"    | Out-File -FilePath $configFile -Append
    "Log: D:\Logs\eventstore"   | Out-File -FilePath $configFile -Append
    "IntIp: $IntIp"             | Out-File -FilePath $configFile -Append
    "ExtIp: $ExtIp"             | Out-File -FilePath $configFile -Append
    "IntTcpPort: $IntTcpPort"   | Out-File -FilePath $configFile -Append
    "IntHttpPort: $IntHttpPort" | Out-File -FilePath $configFile -Append
    "ExtTcpPort: $ExtTcpPort"   | Out-File -FilePath $configFile -Append
    "ExtHttpPort: $ExtHttpPort" | Out-File -FilePath $configFile -Append
    "DiscoverViaDns: false"     | Out-File -FilePath $configFile -Append
    "GossipSeed: [$gossipSeed]" | Out-File -FilePath $configFile -Append
    "ClusterSize: $clusterSize" | Out-File -FilePath $configFile -Append
}

#
# Azure VM's have Temporary Storage on D:\  - Store only log data / temp files there
#

Format-DataDisks

Install-Chocolatey -InstallToPath "C:\Chocolatey"
Download-EventStore -DownloadUrl "http://download.geteventstore.com/binaries/EventStore-OSS-Win-v3.0.2.zip" -SaveToPath "D:\EventStore-OSS-Win-v3.0.2.zip"
Extract-ZipFile -file "D:\EventStore-OSS-Win-v3.0.2.zip" -destination "C:\EventStore\v3.0.2\"

New-EventStoreConfigFile

choco install nssm --version 2.24.0
#choco install logstash
#choco install timberwinr

#
#
#
$ipAddress = (Resolve-DnsName $env:COMPUTERNAME -Type A).IPAddress

#Database Node Internal HTTP Interface (open source and commercial)
netsh http add urlacl url=http://${ipAddress}:${IntHttpPort}/ user="NT AUTHORITY\LOCAL SERVICE"

# Database Node External HTTP Interface (open source and commercial)
netsh http add urlacl url=http://${ipAddress}:${ExtHttpPort}/ user="NT AUTHORITY\LOCAL SERVICE"

# Manager Node Internal HTTP Interface (commercial only)
#netsh http add urlacl url=http://$ipAddress:30777/ user="NT AUTHORITY\LOCAL SERVICE"

# Manager Node External HTTP Interface (commercial only)
#netsh http add urlacl url=http://$ipAddress:30778/ user="NT AUTHORITY\LOCAL SERVICE"

# Added all the ports, but think I only require the 2112,2113 ports
New-NetFirewallRule -Name Allow_EventStore_Int_In -DisplayName "Allow inbound Internal Event Store traffic" -Protocol TCP -Direction Inbound -Action Allow -LocalPort ${IntTcpPort},${IntHttpPort}
New-NetFirewallRule -Name Allow_EventStore_Ext_In -DisplayName "Allow inbound External Event Store traffic" -Protocol TCP -Direction Inbound -Action Allow -LocalPort ${ExtTcpPort},${ExtHttpPort}

C:\Chocolatey\lib\NSSM.2.24.0\Tools\nssm-2.24\win64\nssm.exe install EventStore C:\EventStore\v3.0.2\EventStore.ClusterNode.exe --config C:\EventStore\EventStore-Config.yaml
C:\Chocolatey\lib\NSSM.2.24.0\Tools\nssm-2.24\win64\nssm.exe set EventStore Description "The EventStore service."


#net start EventStore