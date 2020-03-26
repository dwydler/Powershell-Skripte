<#
Das PowerShell Skript liest die aktiven Sitzungen auf dem VMware Connection Server aus.
Die Werte werden als separaten Kanal im Sensor ausgegeben.


THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
This script returns Xml for a custom PRTG sensor providing the following channels
- Aktive Sitzungen
- Interne Sitzungen
- Externe Sitzungen
- Physikalische Sitzungen
- Getrennte Sitzungen


.PARAMETER PrtgDevice
Full Qualified Domain Name des Geräts aus PRTG, welchem den Sensor zugeordnet ist.

.PARAMETER WindowsUsername
Angabe des Windows Benutzers, mit dem die Verbindung zum VMware Horizon Connection Server aufgebaut wird.

.PARAMETER WindowsPassword
Angabe des Passworts für den angegebenen Windows Benutzer, mit dem die Verbindung zum VMware Horizon Connection Server aufgebaut wird.

.PARAMETER WindowsDomain
Angabe des Namens der Windows Domäne

.INPUTS
None
 
.OUTPUTS
None
 
.NOTES
File:           paessler-prtg_vmware-horizion-user-sessions-stats.ps1
Version:        1.0
Author:         Daniel Wydler
Creation Date:  25.03.2020, 14:44 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
25.03.2020, 14:44 Uhr  Initial community release
26.03.2020, 09:55 Uhr  New channel "Getrennte Sitzungen"
26.03.2020, 10:10 Uhr  Optimize some querys


.COMPONENT
None

.LINK


.EXAMPLE
.\paessler-prtg_vmware-horizion-user-sessions-stats.ps1

#>

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
    [ValidateNotNullOrEmpty()]
    [string] $WindowsUsername,

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=2,
        Mandatory=$false
    )]
    [ValidateNotNullOrEmpty()]
    [string] $WindowsPassword,


    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=3,
        Mandatory=$false
    )]
    [ValidateNotNullOrEmpty()]
    [string] $WindowsDomain

)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Clear-Host


#----------------------------------------------------------[Declarations]----------------------------------------------------------


#-----------------------------------------------------------[Functions]------------------------------------------------------------


#------------------------------------------------------------[Modules]-------------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------


$QueryResult = Invoke-Command -Computername $PrtgDevice -ArgumentList $PrtgDevice, $WindowsUsername, $WindowsPassword, $WindowsDomain  -ScriptBlock {

    ### Variablen übergeben
    param(
        [string] $PrtgDevice,
        [string] $WindowsUsername,
        [string] $WindowsPassword,
        [string] $WindowsDomain
    )


    ### Funktionen
    function LoadPsModule {
        Param (
            [Parameter(
                mandatory=$True,
                Position=0
            )]
            [string] $ModuleName
        )

        if (Get-Module -ListAvailable -Name $ModuleName ) {
            Import-Module $ModuleName
        } 
        else {
            Set-PrtgError "Das Modul '$ModuleName' existiert nicht!"
        }
    }

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


    ###
    LoadPsModule "VMware.VimAutomation.HorizonView"


    ### Deklaration von Variablen
    [string] $strXmlOutput = ""

    [System.Object] $objVMwareHorizonVIewQueryDefinition = New-Object "Vmware.Hv.QueryDefinition"
    [System.Object] $objVMwareHorizonViewQueryService = New-Object "Vmware.Hv.QueryServiceService"
    [System.Object] $objVMwareHorizonViewResults = $null

    [string] $strVMwareHorizonSecurityGatewayDnsInteral = "view.izbw.de"
    [string] $strVMwareHorizonSecurityGatewayDnsExternal = "*uag*"


    ### Aufbau der Verbindung zum angegebenen VMware Horizon View Connection Server
    try {
        Connect-HVServer -Server $PrtgDevice -User $WindowsUsername -Password $WindowsPassword -Domain $WindowsDomain | Out-Null
    }
    catch {
        Set-PrtgError $_.Exception.Message
    }
    

    ### Abfrage der aktiven Sitzungen in VMware Horizon View auf dem Connection Server
    try {
        $objVMwareHorizonVIewQueryDefinition.queryEntityType = 'SessionLocalSummaryView'
        $objVMwareHorizonViewResults = $objVMwareHorizonViewResults=$objVMwareHorizonViewQueryService.QueryService_Query($global:DefaultHVServers[0].ExtensionData, $objVMwareHorizonVIewQueryDefinition)
    }
    catch {
        Set-PrtgError $_.Exception.Message
    }

    try {
        $strXmlOutput = "<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes""?>`n"
        $strXmlOutput += "<prtg>`n"

        $strXmlOutput += Set-PrtgResult -Channel "Aktive Sitzungen" -Value ($objVMwareHorizonViewResults.Results.NamesData | Select-Object -Property UserName, SecurityGatewayDNS).count -Unit Count -ShowChart
        $strXmlOutput += Set-PrtgResult -Channel "Interne Sitzungen" -Value ($objVMwareHorizonViewResults.Results.NamesData | Where-Object { $_.SecurityGatewayDNS -like $strVMwareHorizonSecurityGatewayDnsInteral } | Select-Object -Property UserName | Measure-Object).count -Unit Count -ShowChart
        $strXmlOutput += Set-PrtgResult -Channel "Externe Sitzungen" -Value ($objVMwareHorizonViewResults.Results.NamesData | Where-Object { $_.SecurityGatewayDNS -like $strVMwareHorizonSecurityGatewayDnsExternal } | Select-Object -Property UserName | Measure-Object).count -Unit Count -ShowChart
        $strXmlOutput += Set-PrtgResult -Channel "Physikalische Sitzungen" -Value ($objVMwareHorizonViewResults.Results.NamesData | Where-Object { $_.DesktopSource -like "UNMANAGED" } | Select-Object -Property UserName | Measure-Object).count -Unit Count -ShowChart

        $strXmlOutput += Set-PrtgResult -Channel "Getrennte Sitzungen" -Value ($objVMwareHorizonViewResults | Select-Object -ExpandProperty Results | Select-Object -ExpandProperty NamesData | Where-Object { $_.SecurityGatewayDNS -like "" -and  $_.DesktopSource -like "VIRTUAL_CENTER" } | Select-Object -Property UserName | Measure-Object).count -Unit Count -ShowChart

        $strXmlOutput += "</prtg>"

        # Output Xml
        return $strXmlOutput
    }
    catch {
        Set-PrtgError $_.Exception.Message
    }

    ### Verbindung zum angegebenen VMware Horizon View Connection Server beenden
    try {
        Disconnect-HVServer -Confirm:$false
    }
    catch {
        Set-PrtgError $_.Exception.Message
    }
}

$QueryResult
