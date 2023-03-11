Clear-Host

# FQDN
[string] $strInternalFQDN = "lab03.daniel.wydler.eu"
[string] $strExternalFQDN = "lab03.daniel.wydler.eu"


# Hostname für Exchange Webservices, OWA, Outlook Anywhere, Active Sync:
[string] $strInternalOutlookHostname = "exch." + $strInternalFQDN
[string] $strExternalOutlookHostname = "exch." + $strExternalFQDN

# Hostname für Autodiscover:
[string] $strInternalAutodiscoverHostname = "autodiscover." + $strInternalFQDN
#[string] $strExternalAutodiscoverHostname = "autodiscover." + $strExternalFQDN



### Outlook Web Access (OWA)
[string] $strInternalOwa = "https://" + "$strInternalOutlookHostname" + "/owa"
[string] $strExternalOwa = "https://" + "$strExternalOutlookHostname" + "/owa"

# SubSub Damain for Downloading of inlined pictures in emails
# https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-1730
[string] $strInternalOwaDownloadHostname = "download." + $strInternalOutlookHostname
[string] $strExternalOwaDownloadHostname = "download." + $strExternalOutlookHostname

write-host "OWA URL: $strInternalOwa"
write-host "OWA URL: $strExternalOwa`n"

Get-OwaVirtualDirectory -Server $env:computername | Set-OwaVirtualDirectory -InternalUrl $strInternalOwa -ExternalUrl $strExternalOwa
Get-OwaVirtualDirectory -Server $env:computername | Set-OwaVirtualDirectory -InternalDownloadHostName $strInternalOwaDownloadHostname -ExternalDownloadHostName $strExternalOwaDownloadHostname


### Exchange Control Panel (ECP)
[string] $strInternalEcp = "https://" + "$strInternalOutlookHostname" + "/ecp"
[string] $strExternalEcp = "https://" + "$strExternalOutlookHostname" + "/ecp"

write-host "ECP URL: $strInternalEcp"
write-host "ECP URL: $strExternalEcp`n"

Get-EcpVirtualDirectory -server $env:computername| Set-EcpVirtualDirectory -InternalUrl $strInternalEcp -ExternalUrl $strExternalEcp


### Echange Web Service (EWS)
[string] $strInternalEws = "https://" + "$strInternalOutlookHostname" + "/EWS/Exchange.asmx"
[string] $strExternalEws = "https://" + "$strExternalOutlookHostname" + "/EWS/Exchange.asmx"

write-host "EWS URL: $strInternalEws"
write-host "EWS URL: $strExternalEws`n"

Get-WebServicesVirtualDirectory -server $env:computername | Set-WebServicesVirtualDirectory -InternalUrl $strInternalEws -ExternalUrl $strExternalEws -Confirm:$false -Force


### Exchange ActiveSync (EAS)
[string] $strInternalEas = "https://" + "$strInternalOutlookHostname" + "/Microsoft-Server-ActiveSync"
[string] $strExternalEas = "https://" + "$strExternalOutlookHostname" + "/Microsoft-Server-ActiveSync"

write-host "ActiveSync URL: $strInternalEas"
write-host "ActiveSync URL: $strExternalEas`n"

Get-ActiveSyncVirtualDirectory -Server $env:computername  | Set-ActiveSyncVirtualDirectory -InternalUrl $strInternalEas -ExternalUrl $strExternalEas


### OfflineAdressbuch
[string] $strInternalOab = "https://" + "$strInternalOutlookHostname" + "/OAB"
[string] $strExternalOab = "https://" + "$strExternalOutlookHostname" + "/OAB"

write-host "OAB URL: $strInternalOab"
write-host "OAB URL: $strExternalOab`n"

Get-OabVirtualDirectory -Server $env:computername | Set-OabVirtualDirectory -InternalUrl $strInternalOab -ExternalUrl $strExternalOab


### MAPIoverHTTP (MAPI)
[string] $strInternalMapi = "https://" + "$strInternalOutlookHostname" + "/mapi"
[string] $strExternalMapi = "https://" + "$strExternalOutlookHostname" + "/mapi"

write-host "MAPI URL: $strInternalMapi"
write-host "MAPI URL: $strExternalMapi`n"

Get-MapiVirtualDirectory -Server $env:computername| Set-MapiVirtualDirectory -InternalUrl $strExternalMapi -ExternalUrl $strInternalMapi


### Outlook Anywhere (RPCoverHTTP)
write-host "OA Hostname: $strInternalOutlookHostname"
write-host "OA Hostname: $strExternalOutlookHostname`n"

Get-OutlookAnywhere -Server $env:computername| Set-OutlookAnywhere -Internalhostname $strExternalOutlookHostname -Externalhostname $strInternalOutlookHostname -ExternalClientsRequireSsl:$true `
                    -InternalClientsRequireSsl:$true -ExternalClientAuthenticationMethod "Negotiate"


# Autodiscover Service Connection Point (SCP)
[string] $strAutodiscover = "https://" + "$strInternalAutodiscoverHostname" + "/Autodiscover/Autodiscover.xml"

write-host "Autodiscover URL:" $strAutodiscover

Get-ClientAccessService $env:computername | Set-ClientAccessService -AutoDiscoverServiceInternalUri $strAutodiscover
