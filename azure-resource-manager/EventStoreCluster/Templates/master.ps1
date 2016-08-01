#
# master.ps1
#
param(
	[Int32]$ClusterSize,
	[string]$esVer,
	[string]$nginxVer="1.10.1",
	[string]$nginxUrl="http://nginx.org/download/nginx-1.10.1.zip"
)

$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\ps-output-master.txt -append -noClobber

$downloadDirectory = 'D:\download'
New-Item $downloadDirectory -ItemType Directory | Out-Null

. .\create-data-disks.ps1

# TODO: These parameters should come from the template!
. .\install-eventstore.ps1 -EventStoreVersion $esVer `
						   -nssmDownloadUrl "https://nssm.cc/release/nssm-2.24.zip" `
						   -ClusterSize $ClusterSize `
						   -downloadDirectory $downloadDirectory

. .\install-nginx.ps1 -NGinxVersion $nginxVer `
					  -NGinxDownloadUrl $nginxUrl `
					  -downloadDirectory $downloadDirectory

Stop-Transcript
