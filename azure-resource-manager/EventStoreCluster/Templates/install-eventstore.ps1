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
Extract-ZipFile -File $nssmZip -Destination C:\apps\

$eventStoreZip = Download-FileTo -DownloadUrl $EventStoreDownloadUrl -Path $downloadDirectory
Extract-ZipFile -File $eventStoreZip -Destination C:\apps\eventstore-$EventStoreVersion\

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
New-NetFirewallRule -Name Allow_EventStore_Int_In `
					-DisplayName "Allow inbound Internal Event Store traffic" `
					-Protocol TCP `
					-Direction Inbound `
					-Action Allow `
					-LocalPort ${IntTcpPort},${IntHttpPort} `
					-RemoteAddress 
					-Program %SystemDrive%\apps\eventstore-$EventStoreVersion\EventStore.ClusterNode.exe

New-NetFirewallRule -Name Allow_EventStore_Ext_In `
					-DisplayName "Allow inbound External Event Store traffic" `
					-Protocol TCP `
					-Direction Inbound `
					-Action Allow `
					-LocalPort ${ExtTcpPort},${ExtHttpPort} `
					-Program %SystemDrive%\apps\eventstore-$EventStoreVersion\EventStore.ClusterNode.exe

#
#C:\apps\nssm-2.24\win64\nssm.exe install EventStore C:\apps\eventstore-$EventStoreVersion\EventStore.ClusterNode.exe --config C:\apps\eventstore-config.yaml
#C:\apps\nssm-2.24\win64\nssm.exe set EventStore Description "The EventStore service"
