#
# master.ps1
#

$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\ps-output-master.txt -append -noClobber

& "..\create-data-disks.ps1"
& "..\install-eventstore.ps1"

Stop-Transcript