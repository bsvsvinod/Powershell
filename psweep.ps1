<#
.Title
Enumerate windows shares using WMI and Powershell.
.Description
The script scans a subnet and if the host is online, it will attempt to enumerate the any shares using wmi.
.Instructions
By Vininfosec

#>
######################Beginning of script######################
#Use Test-Connection to ping sweep the entire subnet network. Modify the #$start, $end and $ip variables to match your network.
$start = 186
$end = 188
$start..$end | foreach {
#Modify the subnet address
$ip = "192.168.0.0" -replace "0$",$_
#Output status
Write-Host "Pinging $IP" -Foregroundcolor Cyan
$status = (Test-Connection $ip -Count 1 -Quiet)
$ErrorActionPreference = "silentlycontinue"
$Result = $null
 #Pass the IP address to .Net for DNS name resolution.
 $Result = [System.Net.Dns]::gethostentry($IP)

#Begin processing the results
#If the ping result is true then enumerate the shares. Optionally you can change #the bolded file name
If ($Result)
{
$MyResult = [string]$Result.HostName
write-Host "Resolved. Enumerating shares from $MyResult" -ForegroundColor Green
get-wmiobject win32_share -computer $ip | where {$_.name -NotLike "*$"} | sort-object -property path | select-object __server,Name,Path | export-csv .\wmi-server-shares-temp.csv -notypeinformation -encoding ASCII -force -Append
}

#If the ping result is false, don’t enumerate but export to a csv. Optionally you can #change the bolded file name.
Else
{
$MyResult = "unresolved"
Write-Host "Hostname for $IP $MyResult" -foregroundcolor Red
$ip | export-csv .\vinwmi-servers-not-resolved.csv -notypeinformation -encoding ASCII -force -Append
}

#UNCPath. Optionally you can change the bolded file name
$folder = import-csv .\vinwmi-server-shares-temp.csv | Select-Object -ExpandProperty Name
foreach ($i in $folder)
{
$uncpath = ForEach-Object {("\\"+$MyResult + "\" +$i)}
Write-Host "$uncpath"
import-csv .\vinwmi-server-shares-temp.csv | Select *, @{Name="UNCPath";Expression={$uncpath}} | export-csv .\vinwmi-server-shares.csv -Append -Force -NoTypeInformation
}
}
########################End of script#########################
