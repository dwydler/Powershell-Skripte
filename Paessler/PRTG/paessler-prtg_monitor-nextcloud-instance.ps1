<#
.SYNOPSIS
PRTG Custom Sensor Script for Monitoring NextCloud Intances


THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
This script returns Xml for a custom PRTG sensor providing the following channels
- CPU Load 1 Min
- CPU Load 5 Min
- CPU Load 15 Min
- Memory Total
- Memory in Use
- Swap Total
- Swap Free
- Active Users Last 5min
- Active Users Last 1Hour
- Active Users Last 24Hours
- SQL DB Size
- Share Links without Password
- Apps with Updates

.PARAMETER NcUrl
Full Qualified Domain Name der Nextcloud Instanz, die abgefragt werden soll (z.B. nc.lab02.wydler.eu)

.PARAMETER NcUsername
Angabe des Nextcloud Benutzers, mit dem die Daten via API abgefragt werden sollen.

.PARAMETER NcPassword
Das dazugehörige Passwort für den Benutzernamen der bei dem Parameter NcUsername angegeben worden ist.

.INPUTS
None
 
.OUTPUTS
Output the values in xml format
 
.NOTES
File:           paessler-prtg_monitor-nextcloud-instance.ps1
Version:        1.0
Author:         Daniel Wydler
Creation Date:  20.09.2019, 12:07 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
20.09.2019, 12:07 Uhr  Initial community release
20.09.2019, 14:11 Uhr  Added information header
21.09.2019, 19:25 Uhr  Fixed problems with size unit for memory and swap
21.09.2019, 20:36 Uhr  Added cpu load and hdd free space
21.09.2019, 20:55 Uhr  Fixed decimals of memory, swap and hdd free space
21.09.2019, 21:00 Uhr  Changed output in Set-PrtgError
21.09.2019, 21:10 Uhr  Fixed variable name in Set-PrtgResult
21.09.2019, 21:10 Uhr  Set MaxWarning to "0" for Apps with Updates 
21.09.2019, 21:28 Uhr  Added new channels to description

.COMPONENT


.LINK
https://github.com/freaky-media/PRTGScripts/blob/master/PRTG-NextCloud-Status/Prtg_NextCloud.ps1
https://github.com/dwydler/Powershell-Skripte/tree/master/Paessler/PRTG

.EXAMPLE
.\paessler-prtg_monitor-nextcloud-instance.ps1 "Computername" "Nextcloud Benutzername" "Nextcloud Passwort"
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
 
Param (
    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=0,
        Mandatory=$true
    )]
    [ValidateNotNullOrEmpty()]
    [string] $NcUrl,

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=1,
        Mandatory=$true
    )]
    [ValidateNotNullOrEmpty()]
    [string] $NcUsername,

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=2,
        Mandatory=$true
    )]
    [ValidateNotNullOrEmpty()]
    [string] $NcPassword
)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strNcApiUrl = $null
[string] $strXmlOutput = $null

[System.Object] $obBase64AuthInfo = $null
[System.Object] $obNcHeaders = @{}

[Xml] $xmlGetNCStatusPage = $null

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
    if ($MinWarn)            { $Result += "`t`t<limitminwarning>$MinWarn</limitminwarning>`n"; $LimitMode = $true }
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

#------------------------------------------------------------[Modules]-------------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------


[string] $strNcApiUrl = "https://$NCurl/ocs/v2.php/apps/serverinfo/api/v1/info"
[System.Object] $obBase64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($NcUsername+":"+$NcPassword))

$obNcHeaders[“OCS-APIRequest”] = "true"
$obNcHeaders[“Authorization”]="Basic $obBase64AuthInfo"


try {
    $xmlGetNCStatusPage = Invoke-WebRequest -Method GET -Headers $obNcHeaders -URI $strNcApiUrl -UseBasicParsing
}
catch {
    Set-PrtgError -PrtgErrorText $($_.Exception.Message)
}

if( (-not ($xmlGetNCStatusPage.ocs.meta.status -eq "ok") ) -and ( -not ($xmlGetNCStatusPage.ocs.meta.statuscode -eq "200") ) ) {
    Set-PrtgError -PrtgErrorText "Unbekannter Fehler aufgetreten!"
}
else {
    $strXmlOutput = "<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes""?>`n"
    $strXmlOutput += "<prtg>`n"

    # output cpu load
    $strXmlOutput += Set-PrtgResult -Channel "CPU Load Last 1min" -Value $xmlGetNCStatusPage.ocs.data.nextcloud.system.cpuload.element[0] -Unit CPU -ShowChart
    $strXmlOutput += Set-PrtgResult -Channel "CPU Load Last 5min" -Value $xmlGetNCStatusPage.ocs.data.nextcloud.system.cpuload.element[1] -Unit CPU -ShowChart
    $strXmlOutput += Set-PrtgResult -Channel "CPU Load Last 15min" -Value $xmlGetNCStatusPage.ocs.data.nextcloud.system.cpuload.element[2] -Unit CPU -ShowChart
    
    if ($xmlGetNCStatusPage.ocs.data.nextcloud.system.mem_total -ne "N/A") {
        $strXmlOutput += Set-PrtgResult -Channel "Memory Total" -Value ([int]::Parse($xmlGetNCStatusPage.ocs.data.nextcloud.system.mem_total) * 1024) -Unit BytesMemory -ShowChart -DecimalMode Auto
    }
    if ($xmlGetNCStatusPage.ocs.data.nextcloud.system.mem_free -ne "N/A") {
        $strXmlOutput += Set-PrtgResult -Channel "Memory in Use" -Value ([int]::Parse($xmlGetNCStatusPage.ocs.data.nextcloud.system.mem_free) * 1024) -Unit BytesMemory -ShowChart -DecimalMode Auto
    }
    if ($xmlGetNCStatusPage.ocs.data.nextcloud.system.swap_total -ne "N/A") {
        $strXmlOutput += Set-PrtgResult -Channel "Swap Total" -Value ([int]::Parse($xmlGetNCStatusPage.ocs.data.nextcloud.system.swap_total) * 1024) -Unit BytesMemory -ShowChart -DecimalMode Auto
    }
    if ($xmlGetNCStatusPage.ocs.data.nextcloud.system.swap_free -ne "N/A") {
        $strXmlOutput += Set-PrtgResult -Channel "Swap Free" -Value ([int]::Parse($xmlGetNCStatusPage.ocs.data.nextcloud.system.swap_free) * 1024) -Unit BytesMemory -ShowChart -DecimalMode Auto
    }

    $strXmlOutput += Set-PrtgResult -Channel "Hard Disk Free Space" -Value $xmlGetNCStatusPage.ocs.data.nextcloud.system.freespace -Unit BytesDisk -ShowChart -DecimalMode Auto

    # Output active users
    $strXmlOutput += Set-PrtgResult -Channel "Active Users Last 5min" -Value $xmlGetNCStatusPage.ocs.data.activeUsers.last5minutes -Unit Count -ShowChart
    $strXmlOutput += Set-PrtgResult -Channel "Active Users Last 1Hour" -Value $xmlGetNCStatusPage.ocs.data.activeUsers.last1hour -Unit Count -ShowChart
    $strXmlOutput += Set-PrtgResult -Channel "Active Users Last 24Hours" -Value $xmlGetNCStatusPage.ocs.data.activeUsers.last24hours -Unit Count -ShowChart

    $strXmlOutput += Set-PrtgResult -Channel "Share Links" -Value $xmlGetNCStatusPage.ocs.data.nextcloud.shares.num_shares -Unit Count -ShowChart
    $strXmlOutput += Set-PrtgResult -Channel "Share Links without Password" -Value $xmlGetNCStatusPage.ocs.data.nextcloud.shares.num_shares_link_no_password -Unit Count -ShowChart

    $strXmlOutput += Set-PrtgResult -Channel "Apps with Updates" -Value $xmlGetNCStatusPage.ocs.data.nextcloud.system.apps.num_updates_available -Unit Count -ShowChart -MaxWarn 0

    $strXmlOutput += "</prtg>"

    # Output Xml
    $strXmlOutput
}
