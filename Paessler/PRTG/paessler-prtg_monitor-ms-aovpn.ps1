<#
.SYNOPSIS
PRTG Sensor script to monitor Microsoft Microsoft Always On VPN Service.

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
This script returns Xml for a custom PRTG sensor providing the following channels.

.PARAMETER PrtgDevice
Server name on which the Powershell script should be executed.

.PARAMETER intMinutes
Time interval of the sensor of the respective device in PRTG (e.g. 5),

.PARAMETER winUsername
Username to run the Powershell script on the remote server.
If it is a server in a workgroup, put the computer name before the user name (e.g. PC1\Admin1).

.PARAMETER winPassword
Password for the username of the parameter winUsername.

.INPUTS
None
 
.OUTPUTS
Output the values in xml format
 
.NOTES
File:           paessler-prtg_monitor-ms-aovpn.ps1
Version:        1.0
Author:         Gillian81, Daniel Wydler
Creation Date:  04.09.2022, 00:00 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
04.09.2022, 00:00 Uhr  Initial community release


.COMPONENT

.LINK
https://github.com/Gillian81/PRTG-AOVPN-Connection-statistics/blob/main/AOVPN%20Connection%20statistics.ps1
https://github.com/dwydler/Powershell-Skripte/tree/master/Paessler/PRTG

.EXAMPLE
.\paessler-prtg_monitor-ms-aovpn.ps1 "Computername" "5" "pc1\admin1" "serectpassword"
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
    [int] $intMinutes,

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=2,
        Mandatory=$false
    )]
    [string] $winUsername,

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=3,
        Mandatory=$false
    )]
    [string] $winPassword

)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strXmlOutput = ""

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Set-PrtgError {
	Param (
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
		[string]$PrtgErrorText
	)
	$strXmlOutput = "<?xml version=`"1.0`" encoding=`"utf-8`" standalone=`"yes`" ?>`n"
    $strXmlOutput += "<prtg>`n"
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

# Correct display of special characters
# https://kb.paessler.com/en/topic/64817-how-can-i-show-special-characters-with-exe-script-sensors
ping localhost -n 1 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


# Überprüfe, ob der Intervall übergeben worden ist
if ($intMinutes -eq 0) {
    Set-PrtgError "Kein Abfrageintervall übergeben!"
}
else {
    [ValueType] $timespan = New-TimeSpan -Minutes $intMinutes
}


# Überprüfe, ob Parameter übergeben worden sind
if ([string]::IsNullOrWhiteSpace($winUsername)) {  
    Set-PrtgError "Kein Windows Computer und/oder Benutzername übergeben!"
}
elseif ([string]::IsNullOrWhiteSpace($winPassword)) {  
    Set-PrtgError "Kein Windows Passwort übergeben!"
}


# Prüfe, ob der angebebene Server existiert
if (-not (Test-Connection -Computername $PrtgDevice -Quiet -Count 1) ) {
    Set-PrtgError "Server existiert nicht!"
}


# Convert clear windows credentials to encrypt ps object
$winSecPasswd = ConvertTo-SecureString $winPassword -AsPlainText -Force
$Credentials= New-Object System.Management.Automation.PSCredential ($winUsername, $winSecPasswd) 


# Abfrage auf dem Server
$QueryResult = Invoke-Command -Computername $PrtgDevice -ArgumentList $timespan -Credential $Credentials -ScriptBlock {

    # Declare variables
    param($timespan)
    $obCustomReturn = New-Object -TypeName System.Object
    [datetime] $dtNow = Get-Date

    # Modifies the configuration of a remote access role.
    if ( (Get-RemoteAccessAccounting | Select-Object -ExpandProperty InboxAccountingStatus) -eq "Disabled") {
      Set-RemoteAccessAccounting -EnableAccountingType Inbox
    }

    # Displays the summary statistics of real-time, currently active DirectAccess (DA) and VPN connections
    # and the summary statistics of DA and VPN historical connections for a specified time duration
    $obCustomReturn = Get-RemoteAccessConnectionStatisticsSummary -StartDateTime $($dtNow - $timespan) -EndDateTime $dtNow
  
    # Retrun object
    return $obCustomReturn
}


# Generate PRTG Output
$xmlOutput = "<?xml version=`"1.0`" encoding=""utf-8`" standalone=`"yes`" ?>`n"
$xmlOutput += "<prtg>`n"

$xmlOutput += Set-PrtgResult -Channel "TotalSessions" -Value $QueryResult.TotalSessions -Unit "Connections" -ShowChart
$xmlOutput += Set-PrtgResult -Channel "TotalDASessions" -Value $QueryResult.TotalDASessions -Unit "Connections" -ShowChart
$xmlOutput += Set-PrtgResult -Channel "TotalVpnSessions" -Value $QueryResult.TotalVpnSessions -Unit "Connections" -ShowChart
$xmlOutput += Set-PrtgResult -Channel "MaxConcurrentSessions" -Value $QueryResult.MaxConcurrentSessions -Unit "Connections" -ShowChart
$xmlOutput += Set-PrtgResult -Channel "TotalUniqueDAClients" -Value $QueryResult.TotalUniqueDAClients -Unit "Clients" -ShowChart
$xmlOutput += Set-PrtgResult -Channel "TotalUniqueUsers" -Value $QueryResult.TotalUniqueUsers -Unit "Users" -ShowChart

$xmlOutput += '</prtg>'


# Return Xml
$xmlOutput
