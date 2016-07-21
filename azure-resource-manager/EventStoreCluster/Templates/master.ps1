#
# master.ps1
#

$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\ps-output-master.txt -append -noClobber

. .\create-data-disks.ps1

# TODO: These parameters should come from the template!
. .\install-eventstore.ps1 -EventStoreVersion "3.8.0" `
						   -EventStoreDownloadUrl "http://download.geteventstore.com/binaries/EventStore-OSS-Win-v3.8.0.zip" `
						   -nssmDownloadUrl "https://nssm.cc/release/nssm-2.24.zip" `
						   -ClusterSize 3

. .\install-nginx.ps1 -NGinxVersion "1.10.1" `
					  -NGinxDownloadUrl "https://landdb.blob.core.windows.net/eventstore-cluster-resources/nginx-1.10.1.zip"

Stop-Transcript