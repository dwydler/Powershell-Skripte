<#
Monitor Active Directory User Account Status 

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
This script returns Xml for a custom PRTG sensor providing the following channels
- Locked Out Users
- Disabled Users
- Expired Users - not disabled
- Users with password never expires

.PARAMETER
None

.INPUTS
None
 
.OUTPUTS
Output the values in xml format
 
.NOTES
File:           monitoring-active-directory-user-lockouts.ps1
Version:        1.0
Author:         Daniel Wydler
Creation Date:  26.03.2020, 15:47 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
26.03.2020, 15:47 Uhr  Initial community release


.COMPONENT
ACtive Directory Powershell Module

.LINK


.EXAMPLE
.\monitoring-active-directory-user-lockouts.ps1

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

[int] $intLockedOutUsers = 0
[int] $intDisabledUsers = 0
[int] $intExpiredUsers = 0
[int] $intNotExpiringPassword = 0


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

#------------------------------------------------------------[Modules]-------------------------------------------------------------

#LoadPsModule "ActiveDirectory"


#-----------------------------------------------------------[Execution]------------------------------------------------------------

###
### Abfragen auf den Domain Contoller ausführen
$QueryResult = Invoke-Command -Computername $PrtgDevice -ScriptBlock {
    
    ###
    ### Alle gesperrten Benutzer, die nicht deaktiviert oder abgelaufen sind
    $intLockedOutUsers = (Get-ADUser -Filter {Enabled -eq $true -and objectCategory -eq "person" -and objectClass -eq "user"} `
                            -Properties sAMAccountName,DisplayName,LockedOut,LockoutTime,Enabled,AccountExpirationDate | `
                            Where-Object {$_.lockedout -eq $True -and (($_.AccountExpirationDate -gt (Get-Date) -or ($_.AccountExpirationDate -eq $null) ) ) } ).count

    ###
    ### Alle Benutzer, die deaktiviert sind - Dies ist eine manuelle Aktion in Active Directory
    $intDisabledUsers = (Get-ADUser -Filter {Enabled -eq $false -and objectCategory -eq "person" -and objectClass -eq "user"} `
                        -Properties sAMAccountName,DisplayName,LockedOut,LockoutTime,Enabled,AccountExpirationDate).count

    ###
    ### Alle Benutzer, die nicht deaktiviert, aber bereits abgelaufen sind
    $intExpiredUsers = (Get-ADUser -Filter {Enabled -eq $true -and PasswordNeverExpires -eq $false -and objectCategory -eq "person" -and objectClass -eq "user"} `
                        -Properties sAMAccountName,DisplayName,LockedOut,LockoutTime,Enabled,AccountExpirationDate | `
                        Where-Object {(($_.AccountExpirationDate -lt (Get-Date) -and ($_.AccountExpirationDate -ne $null) ) ) } ).count

    ###
    ### Benutzer mit nicht ablaufenden Kennwörtern, die aktiviert und nicht abgelaufen sind, aber das Passwort nicht ändern können
    $intNotExpiringPassword = (Get-ADUser -Filter {Enabled -eq $true -and PasswordNeverExpires -eq $true -and objectCategory -eq "person" -and objectClass -eq "user"} `
                                -Properties sAMAccountName, DisplayName, LockedOut, LockoutTime, Enabled, AccountExpirationDate, CannotChangePassword | `
                                Where-Object {$_.CannotChangePassword -ne $true } ).count

    ###
    ### Rückgabe Werte
    return $intLockedOutUsers, $intDisabledUsers, $intExpiredUsers, $intNotExpiringPassword
} 



$strXmlOutput = "<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes""?>`n"
$strXmlOutput += "<prtg>`n"

$strXmlOutput += Set-PrtgResult -Channel "Locked Out Users" -Value $QueryResult[0] -Unit Count -ShowChart
$strXmlOutput += Set-PrtgResult -Channel "Disabled Users" -Value $QueryResult[1] -Unit Count -ShowChart
$strXmlOutput += Set-PrtgResult -Channel "Expired Users - not disabled" -Value $QueryResult[2] -Unit Count -ShowChart
$strXmlOutput += Set-PrtgResult -Channel "Users with password never expires and can not change password" -Value $QueryResult[3] -Unit Count -ShowChart

$strXmlOutput += "</prtg>"

# Output Xml
return $strXmlOutput
