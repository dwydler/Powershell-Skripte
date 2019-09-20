<#
.SYNOPSIS
PRTG Sensor script to monitor a NoSpamProxy environment


THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
This script returns Xml for a custom PRTG sensor providing the following channels

- In/Out Success             | Total of inbound/outbound successfully delivered messages over the last X minutes
- Inbound Success            | Number of inbound successfully delivered messages over the last X minutes
- Outbound Success           | Number of outbound successfully delivered messages over the last X minutes
- Inbound PermanentlyBlocked | Number of inbound blocked messages over the last X minutes
- Outbound DeliveryPending   | Number of outbound messages with pending delivery over the last X minutes

.PARAMETER PrtgDevice
Name des Servers, auf dem die NoSpamProxy Intranet Rolle installiert ist.

.PARAMETER intMinutes
Dieser Parameter muss indentisch sein, mit dem Abfrage Interverall des PRTG Sensors, welcher dieses Skript ausführt.Angabe in Minuten!

.PARAMETER NspGatewayRoleName
Mit diesem Parameter kann explizit der Name der NoSpamProxy Gateway Rolle angegeben werden, die ausgewertet werden soll

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
        Mandatory=$true
    )]
   [string] $PrtgDevice,

   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=1,
        Mandatory=$true
    )]
   [int] $intMinutes,

   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=2,
        Mandatory=$false
    )]
   [string] $NspGatewayRoleName
)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------


[array] $aNspSecurityGroups = @("NoSpamProxy Configuration Administrators", "NoSpamProxy Monitoring Administrators")
#[array] $aNspSecurityGroups = @("Benutzer")

# Default warning level for delivery pending messages
[int] $intDeliveryPendingMaxWarn = 10

[string] $strXmlOutput = ""

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Set-PrtgResult {
    Param (
        [Parameter(mandatory=$True,Position=0)]
        [string]$Channel,
    
        [Parameter(mandatory=$True,Position=1)]
        [string]$Value,
    
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
    if ($MaxError)           { $Result += "`t`t<limitminwarning>$MinWarn</limitminwarning>`n"; $LimitMode = $true }
    if ($MaxError)           { $Result += "`t`t<limitmaxerror>$MaxError</limitmaxerror>`n"; $LimitMode = $true }
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

function Set-PrtgError {
	Param (
		[Parameter(
            Mandatory=$true
        )]
        [ValidateNotNullOrEmpty()]
		[string]$PrtgErrorText
	)
	
	@"
<prtg>
  <error>1</error>
  <text>$PrtgErrorText</text>
</prtg>
"@
exit
}

#-------------------------------------------------------------[Modules]------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Überprüfe, ob der Intervall übergeben worden ist
if ($intMinutes -eq 0) {
    Set-PrtgError "Kein Abfrageintervall übergeben!"
}
else {
    [ValueType] $timespan = New-TimeSpan -Minutes $intMinutes
}

# Prüft, ob der ausführenden Benutzer Mitglied in den notwendigen Gruppen ist
$QueryResult = Invoke-Command -Computername $PrtgDevice -ArgumentList (,$aNspSecurityGroups) -ScriptBlock {
    
    param($aNspSecurityGroups)
    
    foreach ($strNspGroup in $aNspSecurityGroups) {
        if( (Get-LocalGroupMember $strNspGroup).Name -contains $([Security.Principal.WindowsIdentity]::GetCurrent().Name) -eq $false ) {
            return "Der Benutzer ist nicht Mitglied der lokalen Gruppe '$strNspGroup'!"
        }
    }
} 

if ($QueryResult -ne $null) {
    Set-PrtgError $QueryResult
}

###
### Abfrage eines bestimmten NoSpamProxy Gateways
###

if ($NspGatewayRoleName) {

    $QueryResult = Invoke-Command -Computername $PrtgDevice -ArgumentList $timespan,$NspGatewayRoleName -ScriptBlock {
    
        param($timespan,$strNspGatewayRoleName)

        if ( -not (Get-NspGatewayRole | Where-Object { $_.Name -eq $strNspGatewayRoleName }) ) {
            return "NspGatewayRoleNotExist"
        }
        
        $outItems = New-Object System.Collections.Generic.List[System.Object]

        $outItems.Add( (Get-NspMessageTrack -Status Success -Age $timespan -Directions FromExternal -GatewayRole $strNspGatewayRoleName).Count)
        $outItems.Add( (Get-NspMessageTrack -Status Success -Age $timespan -Directions FromLocal -GatewayRole $strNspGatewayRoleName).Count)
        $outItems.Add( (Get-NspMessageTrack -Status PermanentlyBlocked -Age $timespan -Directions FromExternal -GatewayRole $strNspGatewayRoleName).Count)
        $outItems.Add( (Get-NspMessageTrack -Status DeliveryPending -Age $timespan -Directions FromLocal -GatewayRole $strNspGatewayRoleName).Count)

        return $outItems
    }

    if ($QueryResult -eq "NspGatewayRoleNotExist") {
        Set-PrtgError "Eine Gatewayrolle mit dem Namen '$NspGatewayRole' existiert nicht!"
    }
}

###
### Abfrage  aller existiernenden NoSpamProxy Gateways
###

else {
    $QueryResult = Invoke-Command -Computername $PrtgDevice -ArgumentList $timespan -ScriptBlock {
    
        param($timespan)

        $outItems = New-Object System.Collections.Generic.List[System.Object]

        $outItems.Add( (Get-NspMessageTrack -Status Success -Age $timespan -Directions FromExternal).Count)
        $outItems.Add( (Get-NspMessageTrack -Status Success -Age $timespan -Directions FromLocal).Count)
        $outItems.Add( (Get-NspMessageTrack -Status PermanentlyBlocked -Age $timespan -Directions FromExternal).Count)
        $outItems.Add( (Get-NspMessageTrack -Status DeliveryPending -Age $timespan -Directions FromLocal).Count)

        return $outItems
    }
}

###
### Generate PRTG Output
###

$xmlOutput = "<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes""?>`n"
$xmlOutput += "<prtg>`n"

$xmlOutput += Set-PrtgResult -Channel "In/Out Success" -Value $($QueryResult[0] + $QueryResult[1]) -Unit Count -ShowChart
$xmlOutput += Set-PrtgResult -Channel "In Success" -Value $QueryResult[0] -Unit Count -ShowChart
$xmlOutput += Set-PrtgResult -Channel "Out Success" -Value $QueryResult[1] -Unit Count -ShowChart
$xmlOutput += Set-PrtgResult -Channel "In PermanentlyBlocked" -Value $QueryResult[2] -Unit Count -ShowChart

if($QueryResult[3] -ne 0) {
    $xmlOutput += Set-PrtgResult -Channel "Out DeliveryPending" -Value $QueryResult[3] -Unit Count -ShowChart -MaxWarn $intDeliveryPendingMaxWarn
}
else {
    $xmlOutput += Set-PrtgResult -Channel "Out DeliveryPending" -Value $QueryResult[3] -Unit Count -ShowChart 
}


$xmlOutput += '</prtg>'

# Return Xml
$xmlOutput
