<#
.SYNOPSIS
Monitors Azure TrafficManager Profiles


THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
This script returns Xml for a custom PRTG sensor providing the following channels

- Traffic Manager Name | Name of the Traffic Manager Object
- Profile Status       | Traffic Manager enabled or disabled
- Monitor Status       | Status of the Traffic Manager
- Entpoints Online     | Number of Entpoints which are Online
- Entpoints Degraded   | Number of Entpoints which are Degraded


.PARAMETER TenantId
Provide TenantId

.PARAMETER SubscriptionId
Provide the SubscriptionID

.PARAMETER ApplicationId
Provide the ApplicationID

.PARAMETER AccessSecret
Provide the Application Secret

.PARAMETER resourceGroupName
Optional: Provide resourceGroupName

.PARAMETER profileName
Optional: Provide profileName

.INPUTS
None
 
.OUTPUTS
Output the values in xml format
 
.NOTES
File:           paessler-prtg_microsoft-azure-traffic-manager.ps1
Version:        1.0
Author:         Daniel Wydler
Creation Date:  14.08.2022, 14:31 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
14.08.2022, 14:31 Uhr  Initial community release


.COMPONENT
None

.LINK
https://github.com/Jannos-443/PRTG-Azure
https://github.com/dwydler/Powershell-Skripte/blob/master/Paessler/PRTG/paessler-prtg_microsoft-azure-traffic-manager.ps1

.EXAMPLE
"PRTG-Azure-TrafficManager.ps1" -ApplicationID 'AppId' -TenantId 'TenantId' -AccessSecret 'AppSecret' -SubscriptionId 'SubId'

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
    [string] $TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=2,
        Mandatory=$true
    )]
    [string] $SubscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=3,
        Mandatory=$true
    )]
    [string] $ApplicationId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=4,
        Mandatory=$true
    )]
    [string] $AccessSecret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=5,
        Mandatory=$false
    )]
    [string] $resourceGroupName = "",

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=6,
        Mandatory=$false
    )]
    [string] $profileName = "",

    [Parameter(
        ValueFromPipelineByPropertyName,
        Position=7,
        Mandatory=$false
    )]
    [switch] $UseFqdn = $true

)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strMsAzureResource = "https://management.core.windows.net/"
[string] $strMsAzureRequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"


$QueryResult = $null

[string] $strOutputText = ""
[string] $strXmlOutput = ""

[string] $strTrMaName = ""
[int] $intTrMaProfileStatus = 0
[int] $intTrMaProfileMonitorStatus = 0
[System.Object] $objTrMaEpOnline = $null
[System.Object] $objTrMaEpDegraded = $null
[System.Object] $objTrMaEpDisabled = $null


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

### Catch all unhandled Errors
$ErrorActionPreference = "Stop"

trap {
    $Output = "line:$($_.InvocationInfo.ScriptLineNumber.ToString()) char:$($_.InvocationInfo.OffsetInLine.ToString()) --- message: $($_.Exception.Message.ToString()) --- line: $($_.InvocationInfo.Line.ToString()) "
    $Output = $Output.Replace("<", "")
    $Output = $Output.Replace(">", "")
    $Output = $Output.Replace("#", "")

    Set-PrtgError -PrtgErrorText $Output
}


#region Get Access Token
try {
    ### Request Token
    $Body = @{
        Grant_Type    = "client_credentials"
        resource      = $strMsAzureResource
        client_Id     = $ApplicationId
        Client_Secret = $AccessSecret
    }

    $ConnectGraph = Invoke-RestMethod -Uri $strMsAzureRequestAccessTokenUri -Method POST -Body $Body
}

catch {
    Set-PrtgError -PrtgErrorText "Error getting Access Token. $($_.Exception.Message)"
}
#endregion


#region Get Profiles
#https://docs.microsoft.com/en-us/rest/api/trafficmanager/profiles/get#profile-get-withendpoints

if (($profileName) -and ($resourceGroupName)) {
   $GraphUrl = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourceGroups/$($resourceGroupName)/providers/Microsoft.Network/trafficmanagerprofiles/$($profileName)?api-version=2018-04-01"
}
elseif ($resourceGroupName) {
    $GraphUrl = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourceGroups/$($resourceGroupName)/providers/Microsoft.Network/trafficmanagerprofiles?api-version=2018-04-01"
}
else {
    $GraphUrl = "https://management.azure.com/subscriptions/$($SubscriptionId)/providers/Microsoft.Network/trafficmanagerprofiles?api-version=2018-04-01"
}


try {
    ### Request authorization
    $Headers = @{
        Authorization = "$($ConnectGraph.token_type) $($ConnectGraph.access_token)"
    }

    ### Query Traffic Manager
    $Result = Invoke-RestMethod -Headers $Headers -Uri $GraphUrl -Method Get

    ###
    if ($Result.value) {
        $QueryResult = $Result.value
    }
    else {
        $QueryResult = $Result
    } 
}
catch {
    Set-PrtgError "Could not MS Graph $($GraphUrl). Error: $($_.Exception.Message)"
}
#endregion



###
### Generate PRTG Output
###
$xmlOutput = "<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes"" ?>`n"
$xmlOutput += "<prtg>`n"


foreach ($objCurItem in $QueryResult) {

    ###
    $strTrMaName = $objCurItem.name

    ### Get Full Qualified Domain Name of the Azure Object
    if ($UseFqdn) {
        $TpName = $objCurItem.properties.dnsConfig.fqdn
    }

    ### Get Profile Status of the Azure Object
    switch ($objCurItem.properties.profileStatus) {
        "Enabled"  { $intTrMaProfileStatus = 0 }
        "Disabled" { $intTrMaProfileStatus = 1 }
    }

    ###
    switch ($objCurItem.properties.monitorConfig.profileMonitorStatus) {
        "Online"            { $intTrMaProfileMonitorStatus = 0 }
        "Disabled"          { $intTrMaProfileMonitorStatus = 1 }
        "Degraded"          { $intTrMaProfileMonitorStatus = 2 }
        "Inactive"          { $intTrMaProfileMonitorStatus = 3 }
        "CheckingEndpoints" { $intTrMaProfileMonitorStatus = 4 }
        "Failed"            { $intTrMaProfileMonitorStatus = 5 }
    }

    ###
    $objTrMaEpOnline = $objCurItem.properties.endpoints   | Where-Object { $_.properties.endpointMonitorStatus -eq "Online" }
    $objTrMaEpDegraded = $objCurItem.properties.endpoints | Where-Object { $_.properties.endpointMonitorStatus -eq "Degraded" }
    $objTrMaEpDisabled = $objCurItem.properties.endpoints | Where-Object { $_.properties.endpointMonitorStatus -eq "Disabled" }

    ###
    if (($intTrMaProfileMonitorStatus -eq 2) -and ($objTrMaEpOnline.count -eq 0)) {
        $intTrMaProfileMonitorStatus = 5
    }


    ###
    if ($objTrMaEpDegraded.count -gt 0) {
        foreach ($Endpoint in $objTrMaEpDegraded) {
            $strOutputText += "$($Endpoint.name), "
        }
        $strOutputText = $strOutputText.Insert(0, "$($profileName) - Offline: ")
    }

    else {
        foreach ($Endpoint in $objTrMaEpOnline) {
            $strOutputText += "$($Endpoint.name), "
        }
        $strOutputText = $strOutputText.Insert(0, "$($profileName) - Online: ")
    }


    ###
    if ($profileName) {
        $xmlOutput += "<Text>$($strOutputText.Trim(" ,"))</Text>`n"

        $xmlOutput += Set-PrtgResult -Channel "profileStatus" -Value $intTrMaProfileStatus -Unit "Status" -ValueLookup "prtg.azure.trafficmanager.profilestatus"
        $xmlOutput += Set-PrtgResult -Channel "profileMonitorStatus" -Value $intTrMaProfileMonitorStatus -Unit "Status" -ValueLookup "prtg.azure.trafficmanager.monitorstatus"
        $xmlOutput += Set-PrtgResult -Channel "Endpoints Online" -Value $(($objTrMaEpOnline | Measure-Object).Count) -Unit Count -ShowChart
        $xmlOutput += Set-PrtgResult -Channel "Endpoints Degraded" -Value $(($objTrMaEpDegraded | Measure-Object).Count) -Unit Count -MaxError 1 -ShowChart
        $xmlOutput += Set-PrtgResult -Channel "Endpoints Disabled" -Value $(($objTrMaEpDisabled | Measure-Object).Count) -Unit Count -MaxWarn 0 -ShowChart
    }
    else {
        $xmlOutput += Set-PrtgResult -Channel "$strTrMaName" -Value $intTrMaProfileMonitorStatus -Unit "Status" -ValueLookup "prtg.azure.trafficmanager.monitorstatus"
    }
}

$xmlOutput += "</prtg>"

# Return Xml
$xmlOutput
