<#
.SYNOPSIS
PRTG Sensor script to monitor the BIN9 statistics

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
File:           paessler-prtg_bind-stats-dns-queries.ps1
Version:        1.0
Author:         Daniel Wydler
Creation Date:  27.04.2019
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
27.04.2019, 11:55 Uhr  Initial community release


.COMPONENT

.LINK
https://codeberg.org/wd/Powershell-Skripte/src/commit/104a05244ab2f32447e3806ab335945f96b1f301/Paessler/PRTG

.EXAMPLE
.\paessler-prtg_bind-stats-dns-queries.ps1 "Computername" "Sensor ID"
.\paessler-prtg_bind-stats-dns-queries.ps1 "URL" "Section of BIND9 Stats" "%sensorid"
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
Param (
   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=0,
        Mandatory=$false
    )]
    [string] $BindStatsUrl ="http://sns01.lab03.daniel.wydler.eu:8053/",

    [Parameter(
        Position=1,
        Mandatory=$false
    )]
    [string] $BindStatsType = "OutgoingQueries",

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=2,
        Mandatory=$false
    )]
    [int] $SensorID = 1

)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strPRTGInstallDir = ""
[string] $strXmlOutput = ""
[string] $strXmlFileName = ""

$curStats = New-Object System.Xml.XmlDocument
$prevStats = New-Object System.Xml.XmlDocument

[bool] $bXmlFileExist = $false

[array] $aBindStatsTypes =@("IncomingRequests", "IncomingQueries", "ResponseCode" ,"NameserverStat", "ZoneStat", "OutgoingQueries")

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


# Überprüfe, ob Parameter übergeben worden sind
if ([string]::IsNullOrWhiteSpace($BindStatsUrl)) {  
    Set-PrtgError "Keine URL an den Sensor übergeben!"
}
elseif ($aBindStatsTypes -notcontains $BindStatsType) {
    Set-PrtgError "Der angegebene Typ ist nicht in diesem Skript definiert."
}
elseif ($SensorID -eq 0) {  
    Set-PrtgError "Keine Sensor ID übergeben! Bitte die Variable %sensorid als Parameter verwenden."
}


# Read out the installation directory of PRTG Network Monitor
$strPRTGInstallDir = (Get-ItemPropertyVAlue "HKLM:\SOFTWARE\WOW6432Node\Paessler\PRTG Network Monitor\" -Name "exepath").TrimEnd("\")

# Create an unqiue file name from type .xml
$strXmlFileName = "bind9stats_$($SensorID).xml"
#$strXmlFileName = "bind9stats_sensor_$($SensorID).xml"


# Download the current Bind9 statistic in xml format into variable
try {
    $curStats.Load( $("$BindStatsUrl") )

}
catch {
    Set-PrtgError "$($_.Exception.Message)"
}

# If XML file exist, load the content of the file into variable and set boolean to TRUE
# Else Write the content of the variable into a xml file on local hardk disk and set boolean to FALSE
If (Test-Path -Path "$($strPRTGInstallDir)\Custom Sensors\EXEXML\$($strXmlFileName)") {

    # Load content of the xml file into variable
    $prevStats.Load("$($strPRTGInstallDir)\Custom Sensors\EXEXML\$($strXmlFileName)")

    # Set variable to true
    $bXmlFileExist = $true
}
else {

    # Save xml file to hard disk
    $curStats.Save("$($strPRTGInstallDir)\Custom Sensors\EXEXML\$($strXmlFileName)") 

    # Set variable to false
    $bXmlFileExist = $false
}


# Section "Incoming Requests"
if ($aBindStatsTypes[0] -eq $BindStatsType) {

    # Filter content of the current xml file and assign the result to an new variable
    [Object] $objCurStats = ($curStats.statistics.server.counters[0].counter | Where-Object {$_.name -notlike 'RESERVED*'})

    # Filter content of the previous xml file and assign the result to an new variable
    [Object] $objprevStats = ($prevStats.statistics.server.counters[0].counter | Where-Object {$_.name -notlike 'RESERVED*'})
}

# Section "Incoming Queries"
elseif ($aBindStatsTypes[1] -eq $BindStatsType) {

    # Filter content of the current xml file and assign the result to an new variable
    [Object] $objCurStats = $curStats.statistics.server.counters[2].counter

    # Filter content of the previous xml file and assign the result to an new variable
    [Object] $objprevStats = $prevStats.statistics.server.counters[2].counter
}

# Section "Response Code"
elseif ($aBindStatsTypes[2] -eq $BindStatsType) {

    # Filter content of the current xml file and assign the result to an new variable
    [Object] $objCurStats = ($curStats.statistics.server.counters[1].counter | Where-Object {$_.name -notlike 'RESERVED*' -and $_.name -notmatch "\d+"})

    # Filter content of the previous xml file and assign the result to an new variable
    [Object] $objprevStats = ($prevStats.statistics.server.counters[1].counter | Where-Object {$_.name -notlike 'RESERVED*' -and $_.name -notmatch "\d+"})
}

# Section "nsstat"
elseif ($aBindStatsTypes[3] -eq $BindStatsType) {

    # Filter content of the current xml file and assign the result to an new variable
    [Object] $objCurStats = $curStats.statistics.server.counters[3].counter

    # Filter content of the previous xml file and assign the result to an new variable
    [Object] $objprevStats = $prevStats.statistics.server.counters[3].counter
}

# Section "ZoneStat"
elseif ($aBindStatsTypes[4] -eq $BindStatsType) {

    # Filter content of the current xml file and assign the result to an new variable
    [Object] $objCurStats = $curStats.statistics.server.counters[4].counter

    # Filter content of the previous xml file and assign the result to an new variable
    [Object] $objprevStats = $prevStats.statistics.server.counters[4].counter
}

# Section "Outgoing Queries"
elseif ($aBindStatsTypes[5] -eq $BindStatsType) {

    # Filter content of the current xml file and assign the result to an new variable
    [Object] $objCurStats = $curStats.statistics.views.view.counters[0].counter

    # Filter content of the previous xml file and assign the result to an new variable
    [Object] $objprevStats = $prevStats.statistics.views.view.counters[0].counter
}

else {
    Set-PrtgError "The handed over section name does not exist yet."
}


# Generate PRTG Output
#region
$output = "<prtg>`n"


for ($i = 0; $i -lt ($objCurStats.name).count; $i++) {

        $output += "`t<result>`n"
        $output += "`t`t<channel>$($objCurStats.name[$i])</channel>`n"

        $value = ($objCurStats).'#text'[$i] - ($objprevStats).'#text'[$i]

        if($value -lt 0 ) {
                $value = ($objCurStats).'#text'[$i]
        }
        elseif( -not ($bXmlFileExist) ){
                $value = ($objCurStats).'#text'[$i]
        }

        $output += "`t`t<value>$($value)</value>`n"
        $output += "`t</result>`n"
    }

$output += "</prtg>"


# Output XML
$output
#endregion

# Save BIND Stats to local hardk disk
$curStats.Save("$($strPRTGInstallDir)\Custom Sensors\EXEXML\$($strXmlFileName)") 

