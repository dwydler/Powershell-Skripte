<#
.SYNOPSIS
PRTG Sensor script to monitor a NoSpamProxy environment


THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
This script returns Xml for a custom PRTG sensor providing the following channels


- Inbound Success            | Number of inbound successfully delivered messages over the last X minutes
- Outbound Success           | Number of outbound successfully delivered messages over the last X minutes
- Inbound PermanentlyBlocked | Number of inbound blocked messages over the last X minutes
- Outbound DeliveryPending   | Number of outbound messages with pending delivery over the last X minutes
- LargeFiles                 | Number of files on the large file server
- Ablauf der NSP Lizenz      | Number of days till the nsp licenses expires
- Probleme                   | Number of nsp issues
- SSL Zertifate *            | Number of days till the tls certifcates of the connectors expires

.PARAMETER PrtgDevice
Name des Servers, auf dem die NoSpamProxy Intranet Rolle installiert ist.

.PARAMETER intMinutes
Dieser Parameter muss indentisch sein, mit dem Abfrage Interverall des PRTG Sensors, welcher dieses Skript ausfuehrt. Angabe in Minuten!

.INPUTS
None
 
.OUTPUTS
Output the values in xml format
 
.NOTES
File:           paessler-prtg_monitor-netatwork-nospamproxy.ps1
Version:        1.1
Author:         Thomas Stensitzki, Daniel Wydler
Creation Date:  02.07.2016, 00:00 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
02.07.2016, 00:00 Uhr  Initial community release
07.09.2019, 16:00 Uhr  Code base revised
08.09.2019, 16:31 Uhr  Query all Gateway Roles
17.09.2019, 17:01 Uhr  Rewrited codebase for query gateway role
21.09.2019, 21:20 Uhr  Changed output in Set-PrtgError
21.09.2019, 21:20 Uhr  Fixed variable name in Set-PrtgResult
24.04.2022, 18:53 Uhr  Code base revised & added new querys
03.09.2022, 16:28 Uhr  Modifications for version 14


The following parameters of the message tracking information are available
-Status: Success | DispatcherError | TemporarilyBlocked | PermanentlyBlocked | PartialSuccess | DeliveryPending | Suppressed | DuplicateDrop | All
-Directions: FromLocal | FromExternal | All

.COMPONENT
NoSpamProxy PowerShell Module

.LINK
http://www.granikos.eu/en/scripts
https://github.com/dwydler/Powershell-Skripte/tree/master/Paessler/PRTG

.EXAMPLE
.\paessler-prtg_monitor-netatwork-nospamproxy.ps1 "Computername" "Intervall des PRTG Sensors"
.\paessler-prtg_monitor-netatwork-nospamproxy.ps1 "Computername" "Intervall des PRTG Sensors" "Name der NSP Gateway Rolle"
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
 
Param (
   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=0,
        Mandatory=$false
    )]
   [string] $PrtgDevice,

   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=1,
        Mandatory=$false
    )]
   [int] $intMinutes
)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# Required NoSpamProxy Groups for this script
[array] $aNspSecurityGroups = @("NoSpamProxy Configuration Administrators", "NoSpamProxy Monitoring Administrators")

# Default warning level for delivery pending messages
[int] $intDeliveryPendingMaxWarn = 10

# PRTG sensor xml structure
[string] $strXmlOutput = ""

# Date and time when the script was run
[datetime] $dtNow = Get-Date

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Set-PrtgError {
	Param (
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
		[string]$PrtgErrorText
	)
	
    $strXmlOutput = "<prtg>`n"
    $strXmlOutput += "`t<error>1</error>`n"
    $strXmlOutput += "`t<text>$PrtgErrorText</text>`n"
    $strXmlOutput += "</prtg>"

    # Output Xml
    $strXmlOutput

    exit
}

function Set-PrtgResult {
    Param (
        [Parameter(mandatory=$True,Position=0)]
        [string]$Channel,
    
        [Parameter(mandatory=$True,Position=1)]
        $Value,
    
        [Parameter(mandatory=$True,Position=2)]
        [string]$Unit,

        [Parameter(mandatory=$False)]
        [alias('mw')]
        [string]$MaxWarn,

        [Parameter(mandatory=$False)]
        [alias('minw')]
        [string]$MinWarn,
    
        [Parameter(mandatory=$False)]
        [alias('me')]
        [string]$MaxError,

        [Parameter(mandatory=$False)]
        [alias('mine')]
        [string]$MinError,
    
        [Parameter(mandatory=$False)]
        [alias('wm')]
        [string]$WarnMsg,
    
        [Parameter(mandatory=$False)]
        [alias('em')]
        [string]$ErrorMsg,
    
        [Parameter(mandatory=$False)]
        [alias('mo')]
        [string]$Mode,
    
        [Parameter(mandatory=$False)]
        [alias('sc')]
        [switch]$ShowChart,
    
        [Parameter(mandatory=$False)]
        [alias('ss')]
        [ValidateSet('One','Kilo','Mega','Giga','Tera','Byte','KiloByte','MegaByte','GigaByte','TeraByte','Bit','KiloBit','MegaBit','GigaBit','TeraBit')]
        [string]$SpeedSize,

        [Parameter(mandatory=$False)]
        [ValidateSet('One','Kilo','Mega','Giga','Tera','Byte','KiloByte','MegaByte','GigaByte','TeraByte','Bit','KiloBit','MegaBit','GigaBit','TeraBit')]
        [string]$VolumeSize,
    
        [Parameter(mandatory=$False)]
        [alias('dm')]
        [ValidateSet('Auto','All')]
        [string]$DecimalMode,
    
        [Parameter(mandatory=$False)]
        [alias('w')]
        [switch]$Warning,
    
        [Parameter(mandatory=$False)]
        [string]$ValueLookup
    )
    
    $StandardUnits = @('BytesBandwidth','BytesMemory','BytesDisk','Temperature','Percent','TimeResponse','TimeSeconds','Custom','Count','CPU','BytesFile','SpeedDisk','SpeedNet','TimeHours')
    $LimitMode = $false
    
    $Result  = "`t<result>`n"
    $Result += "`t`t<channel>$Channel</channel>`n"
    $Result += "`t`t<value>$Value</value>`n"
    
    if ($StandardUnits -contains $Unit) {
        $Result += "`t`t<unit>$Unit</unit>`n"
    }
    elseif ($Unit) {
        $Result += "`t`t<unit>custom</unit>`n"
    $Result += "`t`t<customunit>$Unit</customunit>`n"
    }
    
    if (!($Value -is [int])) { $Result += "`t`t<float>1</float>`n" }
    if ($Mode)               { $Result += "`t`t<mode>$Mode</mode>`n" }
    if ($MaxWarn)            { $Result += "`t`t<limitmaxwarning>$MaxWarn</limitmaxwarning>`n"; $LimitMode = $true }
    if ($MinWarn)            { $Result += "`t`t<limitminwarning>$MinWarn</limitminwarning>`n"; $LimitMode = $true }
    if ($MaxError)           { $Result += "`t`t<limitmaxerror>$MaxError</limitmaxerror>`n"; $LimitMode = $true }
    if ($MinError)           { $Result += "`t`t<limitminerror>$MinError</limitminerror>`n"; $LimitMode = $true }
    if ($WarnMsg)            { $Result += "`t`t<limitwarningmsg>$WarnMsg</limitwarningmsg>`n"; $LimitMode = $true }
    if ($ErrorMsg)           { $Result += "`t`t<limiterrormsg>$ErrorMsg</limiterrormsg>`n"; $LimitMode = $true }
    if ($LimitMode)          { $Result += "`t`t<limitmode>1</limitmode>`n" }
    if ($SpeedSize)          { $Result += "`t`t<speedsize>$SpeedSize</speedsize>`n" }
    if ($VolumeSize)         { $Result += "`t`t<volumesize>$VolumeSize</volumesize>`n" }
    if ($DecimalMode)        { $Result += "`t`t<decimalmode>$DecimalMode</decimalmode>`n" }
    if ($Warning)            { $Result += "`t`t<warning>1</warning>`n" }
    if ($ValueLookup)        { $Result += "`t`t<ValueLookup>$ValueLookup</ValueLookup>`n" }
    if (!($ShowChart))       { $Result += "`t`t<showchart>0</showchart>`n" }
    
    $Result += "`t</result>`n"
    
    return $Result
}

#-------------------------------------------------------------[Modules]------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Check if an check interval was passed
if ($intMinutes -eq 0) {
    Set-PrtgError "Kein Abfrageintervall angegeben!"
}
else {
    [ValueType] $timespan = New-TimeSpan -Minutes $intMinutes
}

# Check if the server is reachable
if (-not (Test-Connection -Computername $PrtgDevice -Quiet -Count 1) ) {
    Set-PrtgError "Der Server ist per ICMP nicht erreichbar!"
}

# Check if the service user of the PRTG Probe Server are member of the required groups
try {
    $QueryResult = Invoke-Command -Computername $PrtgDevice -ArgumentList ($aNspSecurityGroups) -ErrorAction Stop -ScriptBlock {
    
        param($aNspSecurityGroups)
    
        foreach ($strNspGroup in $aNspSecurityGroups) {
            if( (Get-LocalGroupMember $strNspGroup).Name -contains $([Security.Principal.WindowsIdentity]::GetCurrent().Name) -eq $false ) {
                return "Der Benutzer ist nicht Mitglied der lokalen Gruppe '$strNspGroup'!"
            }
        }
    } 
}
catch {
    if($_.Exception -like "*Access is denied*") {
        Set-PrtgError "Benutzer `"$env:USERNAME`" ist nicht Mitglied der Gruppe 'Remoteverwaltungsbenutzer'!"
    }
    else {
        Set-PrtgError $_.Exception
    }
}

# Check if the return value of the query are empty
if ($null -ne $QueryResult) {
    Set-PrtgError $QueryResult
}

###
### Query all existing NoSpamProxy Gateways
###

$QueryResult = Invoke-Command -Computername $PrtgDevice -ArgumentList $timespan -ScriptBlock {
       
    # Declare variables
    param($timespan)
    $obCustomReturn = New-Object -TypeName System.Object

    # Fetch of NSP Message Tracking details ofe every Gateway Rolle
    [array] $aNspNspMessageTrack = @()

    Get-NspGatewayRole | Select-Object Name | ForEach-Object {  
        $NspGatewayRole = $_ 
        
        $aNspNspMessageTrack += [pscustomobject]@{ NspGatewayRole="$($NspGatewayRole.Name) - InSuccess"; Anzahl=$(Get-NspMessageTrack -Status Success -Age $timespan -Directions FromExternal -GatewayRole ($_.Name)).Count }
        $aNspNspMessageTrack += [pscustomobject]@{ NspGatewayRole="$($NspGatewayRole.Name) - OutSuccess"; Anzahl=$(Get-NspMessageTrack -Status Success -Age $timespan -Directions FromLocal -GatewayRole ($_.Name)).Count }
        $aNspNspMessageTrack += [pscustomobject]@{ NspGatewayRole="$($NspGatewayRole.Name) - PermanentlyBlocked"; Anzahl=$(Get-NspMessageTrack -Status PermanentlyBlocked -Age $timespan -Directions FromExternal -GatewayRole ($_.Name)).Count }
        $aNspNspMessageTrack += [pscustomobject]@{ NspGatewayRole="$($NspGatewayRole.Name) - OutboundPending"; Anzahl=$(Get-NspMessageTrack -Status DeliveryPending -Age $timespan -Directions FromLocal -GatewayRole ($_.Name)).Count }
    }
    $obCustomReturn | Add-Member -MemberType NoteProperty -Name "NspMessageTrack" -Value $aNspNspMessageTrack

    # Fetch of NSP Large File details
    $obCustomReturn | Add-Member -MemberType NoteProperty -Name "LargeFiles" -Value (Get-NspLargeFile).count

    # Fetch of NSP License details
    $obCustomReturn | Add-Member -MemberType NoteProperty -Name "Lic" -Value (Get-NspLicense | Select-Object $_)

    # Fetch of NSP issues 
    $obCustomReturn | Add-Member -MemberType NoteProperty -Name "Issues" -Value (Get-NspIssue).Count
        
    # Fetch of SSL Certificates from every connector
    [array] $aNspTlsCertificates = @()

    # Fetch informations from all receive connectors
    Get-NspReceiveConnector | Select-Object Name, TlsCertificate | Where-Object { $_.TlsCertificate -notlike "None" } | ForEach-Object {            
        $NspReceiveConnector = $_

        $aNspTlsCertificates += [pscustomobject]@{ Connectorname=$($NspReceiveConnector.Name); CertNotAfter=$((Get-ChildItem "Cert:\LocalMachine\My" | `
                                Where-Object { $_.Thumbprint -match $NspReceiveConnector.TlsCertificate.Thumbprint.ToUpper() }).NotAfter) }
    }

    # Fetch informations from all outbound send connectors
    Get-NspOutboundSendConnector | Select-Object Name, Dispatchers | Where-Object { $_.Dispatchers -ne $null } | foreach-Object { 

        $NspOutboundSendConnector = $_
        $NspOutboundSendConnectorDispatchers = Get-NspOutboundSendConnector -Name $NspOutboundSendConnector.Name | Select-Object Dispatchers
	
        foreach ($connector in $NspOutboundSendConnectorDispatchers.Dispatchers) {
            $aNspTlsCertificates += [pscustomobject]@{ Connectorname="$($NspOutboundSendConnector.Name)"; CertNotAfter=$((Get-ChildItem "Cert:\LocalMachine\My" | `
                                    Where-Object { $_.Thumbprint -match $connector.TlsCertificateThumbprint.ToUpper() }).NotAfter) }	
        }
    }

    # Fetch informations from all inbound send connectors
    [NoSpamProxy.Odata.Configuration.SendConnector] $NspinboundSendConnector = Get-NspInboundSendConnector -Type SMTP

    for ($i = 0; $i -lt $NspinboundSendConnector.Count; $i++) {

        foreach ($smarthosts in $NspinboundSendConnector[$i].Configuration.Dispatchers) {

            $aNspTlsCertificates += [pscustomobject]@{ Connectorname="$($NspinboundSendConnector[$i].Configuration.Name) - $($smarthosts.Smarthost)"; CertNotAfter=$((Get-ChildItem "Cert:\LocalMachine\My" | `
                                    Where-Object { $_.Thumbprint -match $smarthosts.TlsCertificateThumbprint.ToUpper() }).NotAfter) }
        }
    }
    
    $obCustomReturn | Add-Member -MemberType NoteProperty -Name "TlsCertificateNotAfter" -Value $aNspTlsCertificates
	
    
    # Retrun object
    return $obCustomReturn
}

###
### Generate PRTG Output
###

$xmlOutput = "<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes""?>`n"
$xmlOutput += "<prtg>`n"

# Output of InSuccess, OutSuccess, PermanentlyBlocked and PermanentlyBlocked
foreach ($entry in $QueryResult.NspMessageTrack) {

    If($entry.NspGatewayRole -like "*OutboundPending") {
        $xmlOutput += Set-PrtgResult -Channel $entry.NspGatewayRole -Value $entry.Anzahl -Unit Mails -ShowChart -MaxWarn $intDeliveryPendingMaxWarn
    }
    else {
        $xmlOutput += Set-PrtgResult -Channel $entry.NspGatewayRole -Value $entry.Anzahl -Unit Mails -ShowChart
    }

}

# Output of Large Files on the web server
$xmlOutput += Set-PrtgResult -Channel "LargeFiles" -Value $QueryResult.LargeFiles -Unit Dateien -ShowChart

# Output of number of days till the nsp license expires
$xmlOutput += Set-PrtgResult -Channel "Ablauf der NSP Lizenz" -Value (($QueryResult.Lic.ServiceContractExpiresOn - $dtNow).Days) -Unit Tage -MinWarn 60 -MinError 30

# Output of NSP issues
if($QueryResult.Issues -eq "1") {
    $xmlOutput += Set-PrtgResult -Channel "Problem(e)" -Value $QueryResult.Issues -Unit Vorfall -ShowChart -MaxWarn 1 -MaxError 2
}
else {
    $xmlOutput += Set-PrtgResult -Channel "Problem(e)" -Value $QueryResult.Issues -Unit Vorfaelle -ShowChart -MaxWarn 1 -MaxError 2
}

# Output of number of days till the ssl certifcates on the differnet connectors expires
$QueryResult.TlsCertificateNotAfter | ForEach-Object {
    $xmlOutput += Set-PrtgResult -Channel "SSL-Zertifikat des Konnektors '$($_.Connectorname)'" -Value ($_.CertNotAfter - $dtNow).Days -Unit Tage -MinWarn 28 -MinError 14
}

$xmlOutput += "</prtg>"

# Return Xml
$xmlOutput
