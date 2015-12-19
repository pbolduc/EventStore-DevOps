#
# install_eventstore.ps1
#
param (
	[string]
	$EventStoreVersion,
	[string]
	$EventStoreDownloadUrl,
	[string]
	$nssmDownloadUrl,
    [string]
    $IntIp,
    [string]
    $ExtIp,
    [Int]
    $IntTcpPort = 1112,
    [Int]
    $ExtTcpPort = 1113,
    [Int]
    $IntHttpPort = 2112,
    [Int]
    $ExtHttpPort = 2113,
	[string]
	$ExtIpAdvertiseAs

)

function Extract-ZipFile($file, $destination)
{
	#Add-Type -Assembly System.IO.Compression.FileSystem
	#[System.IO.Compression.ZipFile]::ExtractToDirectory($file,$destination)

    if (![System.IO.Directory]::Exists($destination)) {
        [System.IO.Directory]::CreateDirectory($destination)
    }
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item)
    }
}

function Download-FileTo($DownloadUrl, $path) {
	$uri = [System.Uri]$DownloadUrl
	$filename = $uri.Segments[$uri.Segments.Length-1]
	$outFile = Join-Path $path -ChildPath $filename

	Invoke-WebRequest $DownloadUrl -OutFile $outFile | Out-Null
	return $outFile
}

$downloadDirectory = 'D:\download'
New-Item $downloadDirectory -ItemType Directory | Out-Null

$nssmZip = Download-FileTo -DownloadUrl $nssmDownloadUrl -Path $downloadDirectory
# NSSM is packed with in a folder already
Extract-ZipFile -File $nssmZip -Destination F:\apps\

$eventStoreZip = Download-FileTo -DownloadUrl $EventStoreDownloadUrl -Path $downloadDirectory
Extract-ZipFile -File $eventStoreZip -Destination F:\apps\eventstore\$EventStoreVersion\

#
#
#
$ipAddress = (Resolve-DnsName $env:COMPUTERNAME -Type A).IPAddress

#Database Node Internal HTTP Interface (open source and commercial)
#netsh http add urlacl url=http://${ipAddress}:${IntHttpPort}/ user="NT AUTHORITY\LOCAL SERVICE"

# Database Node External HTTP Interface (open source and commercial)
#netsh http add urlacl url=http://${ipAddress}:${ExtHttpPort}/ user="NT AUTHORITY\LOCAL SERVICE"

# Manager Node Internal HTTP Interface (commercial only)
#netsh http add urlacl url=http://$ipAddress:30777/ user="NT AUTHORITY\LOCAL SERVICE"

# Manager Node External HTTP Interface (commercial only)
#netsh http add urlacl url=http://$ipAddress:30778/ user="NT AUTHORITY\LOCAL SERVICE"

# Added all the ports, but think I only require the 2112,2113 ports
New-NetFirewallRule -Name Allow_EventStore_Int_In `
					-DisplayName "Allow inbound Internal Event Store traffic" `
					-Protocol TCP `
					-Direction Inbound `
					-Action Allow `
					-LocalPort ${IntTcpPort},${IntHttpPort}

New-NetFirewallRule -Name Allow_EventStore_Ext_In `
					-DisplayName "Allow inbound External Event Store traffic" `
					-Protocol TCP `
					-Direction Inbound `
					-Action Allow `
					-LocalPort ${ExtTcpPort},${ExtHttpPort}

-MemDb -Log D:\eventstore\logs -ClusterSize 3 -DiscoverViaDns false -GossipSeed %IP0%:2112,%IP1%:2112,%IP2%:2112

EventStore.ClusterNode.exe %COMMON_OPTS% -IntIp %IP0% -ExtIp %IP0% -ExtIpAdvertiseAs %PIP0%
EventStore.ClusterNode.exe %COMMON_OPTS% -IntIp %IP1% -ExtIp %IP1% -ExtIpAdvertiseAs %PIP1%
EventStore.ClusterNode.exe %COMMON_OPTS% -IntIp %IP2% -ExtIp %IP2% -ExtIpAdvertiseAs %PIP2%
					
Add-Content F:\apps\eventstore\config.yaml "# default Event Store configuration file`n"
Add-Content F:\apps\eventstore\config.yaml "Db:               F:\apps\eventstore\data`n"
Add-Content F:\apps\eventstore\config.yaml "Log:              D:\eventstore\logs`n"
Add-Content F:\apps\eventstore\config.yaml "IntIp:            $ipAddress`n"
Add-Content F:\apps\eventstore\config.yaml "ExtIp:            $ipAddress`n"
Add-Content F:\apps\eventstore\config.yaml "ExtIpAdvertiseAs: $ExtIpAdvertiseAs`n"
Add-Content F:\apps\eventstore\config.yaml "ClusterSize:      3`n"
Add-Content F:\apps\eventstore\config.yaml "DiscoverViaDns:   false`n"
Add-Content F:\apps\eventstore\config.yaml "GossipSeed:       10.0.1.4:$IntHttpPort,10.0.1.5:$IntHttpPort,10.0.1.6:$IntHttpPort`n"

#
C:\apps\nssm-2.24\win64\nssm.exe install EventStore F:\apps\eventstore\$EventStoreVersion\EventStore.ClusterNode.exe --config F:\apps\eventstore\config.yaml
C:\apps\nssm-2.24\win64\nssm.exe set EventStore Description "The EventStore service"
