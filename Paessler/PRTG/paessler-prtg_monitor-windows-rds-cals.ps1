<#
.SYNOPSIS
PRTG Sensor script to monitor the Microsoft RDS CALs


THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
This script returns Xml for a custom PRTG sensor providing the following channels

- Gesamtanzahl        | The nummer of total CALs to users
- In Benutzung        | The number of used/assigned CALs to users
- Text                | The OS and the type of RDS CALs



.PARAMETER PrtgDevice
Name des Servers, auf dem der Sensor ausgeführt werden soll


.INPUTS
None
 
.OUTPUTS
Output the values in xml format
 
.NOTES
File:           paessler-prtg_monitor-windows-rds-cals.ps1
Version:        1.0
Author:         Daniel Wydler
Creation Date:  19.02.2023, 16:09 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
19.02.2023, 16:09 Uhr  Initial community release


.COMPONENT
None

.LINK
https://social.technet.microsoft.com/Forums/fr-FR/e20f716e-f0f4-480b-affb-893d55f712c2/rds-remote-desktop-services-license-usage-report-automation?forum=winserverTS

.EXAMPLE
.\paessler-prtg_monitor-windows-rds-cals.ps1 "$PrtgDevice"

#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
 
Param (
   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=0,
        Mandatory=$true
    )]
   [string] $PrtgDevice
)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strXmlOutput = ""

[int] $intRdsCalsSum = 0
[int] $intRdsCalsInUse = 0
[int] $intRdsCalsInUsePercent = 0

[string] $strProductVersion = ""
[string] $strRdsCalsType =""


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

# Assign param to variables
[string] $strServerName = $PrtgDevice


# Generate a RDS license report
[string] $strRdsLicReportFfileName = (Invoke-WmiMethod Win32_TSLicenseReport -comp $strServerName -Name GenerateReportEx).FileName

# Query informations from the RDS license report
$summaryEntries = (Get-WmiObject -Class Win32_TSLicenseReport -Namespace root/cimv2 -comp $strServerName | Where-Object FileName -eq $strRdsLicReportFfileName).FetchReportSummaryEntries(0,0).ReportSummaryEntries 

# Delete the previously created report
$Result = Get-WmiObject -Class Win32_TSLicenseReport -Namespace root/cimv2 -comp $strServerName | Where-Object { $_.FileName -eq $strRdsLicReportFfileName } | ForEach-Object { $_.DeleteReport() }
 

# Assign values of the RDS license report to dedicated variables
$intRdsCalsSum = $summaryEntries.InstalledLicenses
$intRdsCalsInUse = $summaryEntries.IssuedLicenses
$intRdsCalsInUsePercent = 100 - ( ($intRdsCalsInUse / $intRdsCalsSum) * 100)
$strProductVersion = $summaryEntries.ProductVersion
$strRdsCalsType = $summaryEntries.TSCALType


# Generate PRTG Output
$xmlOutput = "<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes"" ?>`n"
$xmlOutput += "<prtg>`n"

$xmlOutput += Set-PrtgResult -Channel "Gesamtanzahl" -Value $intRdsCalsSum -Unit Custom -ShowChart 
$xmlOutput += Set-PrtgResult -Channel "In Benutzung" -Value $intRdsCalsInUse -Unit Custom -ShowChart
$xmlOutput += Set-PrtgResult -Channel "In Benutzung (%)" -Value $intRdsCalsInUsePercent -Unit Custom -MinWarn 25 -MinError 10 -ShowChart

$xmlOutput += "<Text>$strProductVersion, $strRdsCalsType</Text>" 
$xmlOutput += "</prtg>"

# Return Xml
$xmlOutput