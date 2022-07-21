Clear-Host

[bool] $bEnableIPv6 = $false

[string] $strIanaTldsFile = "https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
[array] $aIanaTlds = ""

[string] $DnsIpRawFile = "$pwd\ips.raw.txt"
[String] $DnsIPUniqFile = "$pwd\ips.uniq.txt"


# Cloudflare
#[array] $aPublicDnsServers = @("1.1.1.1")

# Google
[array] $aPublicDnsServers = @("8.8.4.4", "8.8.8.8")

# QUAD9
#[array] $aPublicDnsServers = @("9.9.9.9", "149.112.112.112")



### Measure run time of the script
[datetime] $tStartTime = Get-Date


###
Write-Host "Check if old files exists."
if (Test-path $DnsIpRawFile) {
    Remove-Item -Path $DnsIpRawFile -Confirm:$false
    Write-Host "Datei $DnsIpRawFile erfolgreich gelöscht."
}

if (Test-path $DnsIPUniqFile) {
    Remove-Item -Path $DnsIPUniqFile -Confirm:$false
    Write-Host "Datei $DnsIPUniqFile erfolgreich gelöscht."
}


###
Write-Host "Download current TLD list."
$aIanaTlds = ( (Invoke-WebRequest -Uri $strIanaTldsFile -Method Get) -split '\r?\n').Trim()
Write-Host "File successfully downloaded."


###
$i = 1
foreach ($strTld in ($aIanaTlds | select -Skip 1) ) {
    
    ##
    Write-Host $i
    Write-Host $strTld

    ##
    [string] $strRandomDnsServer = Get-Random -InputObject $aPublicDnsServers

    ##
    [array] $aDnsServerList = Resolve-DnsName -Name "$strTld." -Type NS -Server $strRandomDnsServer
    
    ##
    foreach ($strDns in ($aDnsServerList.NameHost)) {

        if ($bEnableIPv6) {
            Resolve-DnsName -Name "$strDns" -Server $strRandomDnsServer
        }
        else {
            try {
                Resolve-DnsName -Name "$strDns" -Type "A" -Server $strRandomDnsServer -ErrorAction Stop | Select-Object -ExpandProperty IPAddress -ErrorAction Stop | Out-File -FilePath $DnsIpRawFile -Append
            }
            catch {
                $_.Exception.Message
                #Pause
            }
        }
    }

    ##
    $i++ 
    #break
}


###
Get-Content $DnsIpRawFile | sort | Group-Object | Where-Object { $_.Count -ge 1 } | Select -ExpandProperty Name | Out-File -FilePath $DnsIPUniqFile


(Get-Content $DnsIpRawFile | Measure-Object -Line).Lines
(Get-Content $DnsIPUniqFile | Measure-Object -Line).Lines

### Measure run time of the script
sleep -Seconds 5
[datetime] $tEndTime = Get-Date
Write-Host "Laufzeit: $(($tEndTime - $tStartTime).ToString("hh\:mm\:ss")) (Std:Min:Sek)"

exit
