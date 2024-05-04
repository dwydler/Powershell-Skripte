<#
.SYNOPSIS
PRTG Sensor script to monitor a certificate revocation list (CRL)


THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
This script returns Xml for a custom PRTG sensor providing the following channels

- CA Name             | Full Name of the CA
- CRL Valid           | Validity of the CRL (true=1 or False=0)
- Created before      | When the CRL was created in Days
- Expiration          | Expiry of the CRL in Days


.PARAMETER PrtgDevice
Name des Servers, auf dem der Sensor ausgeführt werden soll

.PARAMETER CrlUrl
Vollständige Adresse der CRL

.INPUTS
None
 
.OUTPUTS
Output the values in xml format
 
.NOTES
File:           prtg_monitor-check-crl.ps1
Version:        1.0
Author:         Daniel Wydler
Creation Date:  15.12.1021, 13:52 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
15.12.1021, 13:52 Uhr  Initial community release
15.12.1021, 15:13 Uhr  Added new channel


.COMPONENT
None

.LINK
http://powershellcoder.com/index.php/2016/10/08/get-crltimevalidity-part-1/
https://github.com/dwydler/Powershell-Skripte/tree/master/Paessler/PRTG

.EXAMPLE
.\prtg_monitor-check-crl.ps1 "$PrtgDevice" "http://x1.c.lencr.org/"

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
    [string] $CrlUrl
)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strXmlOutput = ""

#set match strings                                                                                                                                      
[string] $strOidCommonName = " 06 03 55 04 03 "
[string] $strUtcTime = " 17 0D "

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

#-------------------------------------------------------------[Modules]------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Überprüfe, ob eine gültige FQDN übergeben wurde.
# https://gist.github.com/mambru82/5b7def452c621786229b2d2535bfa0ee
# https://regex101.com/r/eabm1Y/1
if (-not ($CrlUrl -match "^(http:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.\(\)+-]*)\/?$") ) {
    Set-PrtgError "Internetadresse der CRL nicht korrekt!"
}


# Abruf der CRL Informationen
try { 
    [Microsoft.PowerShell.Commands.WebResponseObject] $objCrlFile = Invoke-WebRequest -Uri $CrlUrl -Method Get -UseBasicParsing:$true 
}
catch {
    Set-PrtgError $_
}


#Import the CRL file to byte array
try {
    [byte[]] $byCrlBytes = $objCrlFile.Content
}
catch {
    Set-PrtgError "Invalid CRL format $_.exception.message"
}


#convert crl bytes to hex string                                                                                                                        
$CRLHexString = ($byCrlBytes | % {"{0:X2}" -f $_}) -join " "


#get the relevent bytes using the match strings                                                                                                         
[System.Array] $saCaNameBytes = ($CRLHexString -split $strOidCommonName)[1] -split " " | % {[Convert]::ToByte("$_",16)}                                                    
[System.Array] $saThisUpdateBytes = ($CRLHexString -split $strUtcTime)[1] -split " "  | % {[Convert]::ToByte("$_",16)}                                                     
[System.Array] $saNextUpdateBytes = (($CRLHexString -split $strUtcTime)[2] -split " ")[0..12] | % {[Convert]::ToByte("$_",16)}                                             

                                                                                                                                                       
#convert data to readable values                                                                                                                        
[string] $strCaName = ($saCaNameBytes[2..($saCaNameBytes[1]+ 1)] | % {[char]$_}) -join ""                                                                               
[DateTime] $dtThisUpdate = [Management.ManagementDateTimeConverter]::ToDateTime(("20" + $(($saThisUpdateBytes | %{[char]$_}) -join ""  -replace "z")) + ".000000+000") 
[DateTime] $dtNextUpdate = [Management.ManagementDateTimeConverter]::ToDateTime(("20" + $(($saNextUpdateBytes | %{[char]$_}) -join ""  -replace "z")) + ".000000+000") 
                                                                                                                                                                
[int]$intIsvalid = [int][bool]::Parse( ($dtNextUpdate -gt (Get-Date) ) )
[int] $intCreatedForDays = [math]::truncate( ((Get-Date) - $dtThisUpdate ).TotalDays)
[int] $intExpirationDays = [math]::truncate( ($dtNextUpdate - (Get-Date) ).TotalDays)


###
### Generate PRTG Output
###

$xmlOutput = "<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes"" ?>`n"
$xmlOutput += "<prtg>`n"

$xmlOutput += Set-PrtgResult -Channel "Valid" -Value $intIsvalid -Unit Custom -ShowChart -ValueLookup "prtg.standardlookups.boolean.statetrueok"
$xmlOutput += Set-PrtgResult -Channel "Created before" -Value $intCreatedForDays -Unit Days -ShowChart
$xmlOutput += Set-PrtgResult -Channel "Expiration" -Value $intExpirationDays -Unit Days -ShowChart

$xmlOutput += "<Text>CA Name: $strCaName</Text>" 
$xmlOutput += "</prtg>"

# Return Xml
$xmlOutput
