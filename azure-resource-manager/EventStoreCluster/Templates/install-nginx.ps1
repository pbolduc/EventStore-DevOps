#
# install_nginx.ps1
#
param (
	[string]
	$NGinxVersion,
	[string]
	$NGinxDownloadUrl
)

function Extract-ZipFile($file, $destination) {
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

$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\ps-output-nginx.txt -append -noClobber

$downloadDirectory = 'D:\download'
#New-Item $downloadDirectory -ItemType Directory | Out-Null

$nginxZip = Download-FileTo -DownloadUrl $NGinxDownloadUrl -Path $downloadDirectory
Extract-ZipFile -File $nginxZip -Destination F:\nginx\bin\

#
#
#
# $ipAddress = (Resolve-DnsName $env:COMPUTERNAME -Type A).IPAddress
					
# TODO: Include reverse proxy 80 to 2113
Add-Content F:\nginx\install-service.cmd "F:\nssm-2.24\win64\nssm.exe install Nginx F:\nginx\bin\nginx.exe"
Add-Content F:\nginx\install-service.cmd "F:\nssm-2.24\win64\nssm.exe set Nginx Description ""The Nginx service"""

Add-Content F:\nginx\start-service.cmd "net start Nginx"
Add-Content F:\nginx\stop-service.cmd "net stop Nginx"

. F:\nginx\install-service.cmd
. F:\nginx\start-service.cmd

Stop-Transcript