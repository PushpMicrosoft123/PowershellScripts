[string]$FijiDownloadPath = "https://downloads.imagej.net/fiji/latest/fiji-win64.zip"

[string]$DestinationPathForFiji = "c:\Users\$($env:USERNAME)"

$webClient = New-Object -TypeName System.Net.WebClient
$webClient.DownloadFile($FijiDownloadPath,  "$($DestinationPathForFiji)\fiji-win64.zip");

#zipping or compressing files
#compress-archive -path 'c:\wwwroot\logs' -destinationpath '.\logs.zip' -compressionlevel optimal

#unzip files with .net core expand-archive
expand-archive -path "$($DestinationPathForFiji)\fiji-win64.zip" -destinationpath "$($DestinationPathForFiji)\fiji-win64"

#launch the application
#Start-Process -path "$($DestinationPathForFiji)\fiji-win64\Fiji.app\ImageJ-win64"
