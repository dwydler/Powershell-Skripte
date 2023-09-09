<#
.SYNOPSIS
If a separate TLS identity is to be used in the receive and send connector, this must first be stored in the computer certificate store on all systems with NoSpamProxy components.
Then the defined service accounts must be granted read permissions on the private key. This interaction is handled by this script. 

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.PARAMETER

.INPUTS
 
.OUTPUTS
The script only prints out information about the various commands it ran.
At the same time, each output is also written to a log.

 
.NOTES
File:           Set-CertificatePermissions.ps1
Author:         Daniel Wydler
Creation Date:  07.01.2023

.COMPONENT
The script supports a multilingual environment. Default language is english. More details on that:
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-localizeddata?view=powershell-7.3
https://docs.nospamproxy.com/Server/14/Suite/de-de/Content/installation/installation-after.htm#web-app-connection

.LINK
https://codeberg.org/wd/Powershell-Skripte/src/branch/master/NoSpamProxy/Set-CertificatePermissions/

.EXAMPLE
.\Set-CertificatePermissions.ps1

#>


#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

### function Write-Log
[string] $strLogfilePath = $(Get-Location).Path
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
[string] $strLogfileNamePrefix = "Log_"
[string] $strLogfileName = $($strLogfileNamePrefix + $strLogfileDate + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName


### Variables for this script 
[string] $strUsernameCurrent = $env:username
[string] $strGroupname = ""

[string] $strCertStorePath = "Cert:\LocalMachine\My"

 
[string] $strNspGatewayRoleServiceName = "NoSpamProxyGatewayRole"
[string] $strNspIntranetRoleServiceName = "NoSpamProxyIntranetRole"
[string] $strNspWebportalRoleServiceName = "NoSpamProxyLargeFileSynchronization"

[array] $aNspGatewayRoleServiceAccounts = ("NT Service\NoSpamProxyGatewayRole", "NT Service\NoSpamProxyManagementService", "NT Service\NoSpamProxyPrivilegedService")
[array] $aNspIntranetRoleServiceAccounts = ("NT Service\NoSpamProxyIntranetRole", "NT Service\NoSpamProxyManagementService", "NT Service\NoSpamProxyPrivilegedService")
[array] $aNspWebPortalRoleServiceAccounts = ("NT Service\NoSpamProxyManagementService", "NT Service\NoSpamProxyPrivilegedService")


#-----------------------------------------------------------[Functions]------------------------------------------------------------

function WorkingDir {
    param (
        [parameter(Position=0)]
        [switch] $Debugging
    )

    # Splittet aus dem vollstaendigen Dateipfad den Verzeichnispfad heraus
    # Beispiel: D:\Daniel\Temp\Unbenannt2.ps1 -> D:\Daniel\Temp
    [string] $strWorkingdir = Split-Path $MyInvocation.PSCommandPath -Parent

    # Wenn Variable wahr ist, gebe Text aus.
    if ($Debugging) {
        Write-Host "[DEBUG] PS $strWorkingdir`>" -ForegroundColor Gray
    }

    # In das Verzeichnis wechseln
    Set-Location $strWorkingdir
}
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $LogText,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Info','Success','Warning','Error')]
        [string] $LogStatus= "Info",

        [Parameter()]
        [switch] $Absatz,

        [Parameter()]
        [switch] $EventLog
    )

	[string] $strLogdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    [string] $strTextColor = "White"
    [string] $strLogFileAbsatz = ""
    [string] $strLogFileHeader = ""

    if ( -not (Test-Path $strLogfilePath) ) {
        Write-Host "Der angegebene Pfad $strLogfilePath existiert nicht!" -ForegroundColor Red
        exit
    }

    # Add a header to logfile, if the logfile not exist
    If ( -not (Test-Path $strLogfile) ) {
        $strLogFileHeader = "$("#" * 120)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Skript:", "$($MyInvocation.ScriptName)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Startzeit:", "$(Get-Date -Format "dd.MM.yyyy HH:mm:ss")`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Startzeit:", "$(Get-Date -Format "dd.MM.yyyy HH:mm:ss")`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# BenutzerKonto:", "$env:username`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Computername:", "$env:COMPUTERNAME`n"
        $strLogFileHeader += "$("#" * 120)`n"

        Write-Host $strLogFileHeader
        Add-Content -Path $strLogfile -Value $strLogFileHeader -Encoding UTF8
    }
   

    switch($LogStatus) {
        Info {
            $strTextColor = "White"
        }
        Success {
            $strTextColor = "Green"
        }
        Warning {
            $strTextColor = "Yellow"
        }
        Error {
            $strTextColor = "Red"
        }
    }

    # Add an Absatz if the parameter is True
    if($Absatz) {
        [string] $strLogFileAbsatz = "`r`n"
    }

    #Format the text output
    $LogText = "{0,-20} - {1,-7} - {2,0}" -f "$strLogdate", "$LogStatus", "$LogText $strLogFileAbsatz"

    # Write output to powershell console
    Write-Host $LogText -ForegroundColor $strTextColor

    # Write output to logfile
    Add-Content -Path $strLogfile -Value $LogText -Encoding UTF8

    # Add Logfile to local Eventlog of the operating system 
    if($EventLog) {
        Write-EventLog -LogName 'Windows PowerShell' -Source "Powershell" -EventId 0 -Category 0 -EntryType $LogStatus -Message $LogText
    }

}

function CheckUserPrivilege {

    Param (
        [Parameter(mandatory=$True,Position=0)]
        [string] $Username,
    
        [Parameter(mandatory=$True,Position=1)]
        [string] $Groupname,

        [Parameter(mandatory=$false,Position=2)]
        [ValidateSet('Computer','Domain')]
        [string] $Scope
    )

    # Check if the group exist on the local computer
    Write-Log -LogText $uiLanguage.CheckUserPrivilegeGroupCheckInfo
    try {
        Get-LocalGroup -Name $Groupname -ErrorAction Stop | Out-Null
        Write-Log -LogText $uiLanguage.CheckUserPrivilegeGroupCheckSuccess -LogStatus "Success" -Absatz
    }
    catch {
        #Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Log -LogText $uiLanguage.CheckUserPrivilegeGroupCheckError -LogStatus "Error" -Absatz
        return $false
    }

    # Check if the computer in a domain or workroup
    if ($env:userdomain -ne $env:computername) {
        $Username = "$($env:userdomain)\$($Username)"
    }

    #Check if the current user member of the group
    Write-Log -LogText $uiLanguage.CheckUserPrivilegeUserMembershipInfo
    try {
        Get-LocalGroupMember -Group $Groupname -Member $Username -ErrorAction $ErrorActionPreference | Out-Null
        Write-Log -LogText $uiLanguage.CheckUserPrivilegeUserMembershipSuccess -LogStatus "Success" -Absatz
    }
    catch {
        #Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Log -LogText $uiLanguage.CheckUserPrivilegeUserMembershipError -LogStatus "Error" -Absatz
        return $false
    }

    return $true
    
}
function ExitScript {

    #Pause
    exit
}

function Set-CertPrivateKeyPermission {
    Param (
        [Parameter(mandatory=$True, Position=0)]
        $AccountName,
    
        [Parameter(mandatory=$True, Position=1)]
        $Certificate,

        [Parameter(mandatory=$True, Position=2)]
        [ValidateSet('Read','FullControl')]
        [string]$Permission
    )
    
    
    # Get private key of the certificate
    [System.Security.Cryptography.RSA] $rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($certificate)

    # Save the unquie file name of the privte key in a variable
    [string] $strCertPrivatKeyFileName = $rsaCert.key.UniqueName

    # Create variable with the full file path
    [string] $strCertPrivateKeyFullPath = "$env:ALLUSERSPROFILE\Microsoft\Crypto\Keys\$strCertPrivatKeyFileName"

    # Readout current access control list from the private key
    [System.Security.AccessControl.FileSystemSecurity] $secCertPrivateKeyPermissions = Get-Acl -Path $strCertPrivateKeyFullPath
        
    # Create new access rule
    [System.Security.AccessControl.AccessRule] $accruCertPrivateKeyAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($AccountName, $Permission, 'None', 'None', 'Allow')

    # Added new access rule to permissions
    $secCertPrivateKeyPermissions.AddAccessRule($accruCertPrivateKeyAccessRule)

    # Set new permissions to the private key
    Set-Acl -Path $strCertPrivateKeyFullPath -AclObject $secCertPrivateKeyPermissions
}

#------------------------------------------------------------[Modules]-------------------------------------------------------------

# Changes to the directory in which the PowerShell script is located
WorkingDir

# Import Locale data
. .\locale\UICulture.ps1

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Host @"
------------------------------------------------------------------------------------------------------------------------

                                        $($uiLanguage.ScriptTitle)

------------------------------------------------------------------------------------------------------------------------
"@
# Make sure the script is started as "Run as administrator".
#Requires -RunAsAdministrator

#
$strGroupname = $uiLanguage.LocalGroupAdministratorsName

# Check, of the current user account
If ( -not (CheckUserPrivilege -Username $strUsernameCurrent -Groupname $strGroupname) ) {
    Write-Log -LogText $uiLanguage.CheckUserPrivilegeError -LogStatus Info
    ExitScript

    #Write-Log -LogText "Please start the script with a user with the necessary rights!" -LogStatus "Error"
}
else {
    Write-Log -LogText $uiLanguage.CheckUserPrivilegeSuccess -LogStatus Info -Absatz
    #write-host -ForegroundColor Green "The current user had enough rights for this script."   
}


# Read out all certifcates in local computer store
Write-Log -LogText $uiLanguage.LocalComputerCertStoreInfo -LogStatus Info
if ( (Get-ChildItem $strCertStorePath).count -eq 0 ) {
    Write-Log -LogText $uiLanguage.LocalComputerCertStoreError -LogStatus Error
    ExitScript
}
else {
    Write-Log -LogText $uiLanguage.LocalComputerCertStoreOk -LogStatus Success -Absatz
    [array] $aCertifcateStoreOverview = Get-ChildItem $strCertStorePath | Select-Object Subject, Issuer, NotBefore, Thumbprint, HasPrivateKey

    Write-Log -LogText "`t$($uiLanguage.LocalComputerCertStoreListTitle)" -LogStatus Info
    for ($i=0; $i -lt $aCertifcateStoreOverview.Count; $i++) {

        $FormatDateTime = Get-Date $aCertifcateStoreOverview[$i].NotBefore -Format "dd.MM.yyyy HH:mm:ss"

        if ($aCertifcateStoreOverview[$i].Subject -eq $aCertifcateStoreOverview[$i].Issuer) {
            Write-Log -LogText "`t$($i): $($FormatDateTime) Uhr, $($aCertifcateStoreOverview[$i].Thumbprint), $($aCertifcateStoreOverview[$i].Subject)" -LogStatus Warning
        }
        elseif ($aCertifcateStoreOverview[$i].HasPrivateKey -eq $true) {
            Write-Log -LogText "`t$($i): $($FormatDateTime) Uhr, $($aCertifcateStoreOverview[$i].Thumbprint), $($aCertifcateStoreOverview[$i].Subject)" -LogStatus Info
        }
        else {
            Write-Log -LogText "`t$($i): $($FormatDateTime) Uhr, $($aCertifcateStoreOverview[$i].Thumbprint), $($aCertifcateStoreOverview[$i].Subject)" -LogStatus Error
        }

    }

    Write-Host "`n"
    Write-Log -LogText $uiLanguage.LocalComputerCertStoreListLegend
}


# Query whether entered value is a number between 1 and x
do {
    [int] $SelectedCertificateId = Read-Host -Prompt "`n$($uiLanguage.QueryCertText1) 1 $($uiLanguage.QueryCertText2) $( ($aCertifcateStoreOverview.Count)-1), -1 = $($uiLanguage.QueryCertAbort)"
}
while ( ($SelectedCertificateId -lt -1) -or ($SelectedCertificateId -gt $aCertifcateStoreOverview.Count) )

# Exit script if condition is met
if($SelectedCertificateId -eq -1) {
    Write-Log -LogText $uiLanguage.ExitScriptMessage -LogStatus Error
    ExitScript
}


# Select certificate based on Thumbprint
Write-Log -LogText "Zertifkat: $($aCertifcateStoreOverview[$SelectedCertificateId].Subject), $($aCertifcateStoreOverview[$SelectedCertificateId].NotBefore), $($aCertifcateStoreOverview[$SelectedCertificateId].Thumbprint)" -LogStatus Info
$certificate = Get-ChildItem $strCertStorePath | Where-Object Thumbprint -eq $aCertifcateStoreOverview[$SelectedCertificateId].Thumbprint


# Set new permissions to the private key of the selected certificate for the gateway role
Write-Log -LogText $uiLanguage.NoSpamProxyGwRoleInfoText -LogStatus Info
If (get-service | Where-Object { $_.Name -eq $strNspGatewayRoleServiceName }) {
    
    #
    foreach ($ServiceAccount in $aNspGatewayRoleServiceAccounts) {
        
        Write-Log -LogText "`t$($uiLanguage.NoSpamProxyGwRoleAccountInfoText1) '$($ServiceAccount)' $($uiLanguage.NoSpamProxyGwRoleAccountInfoText2)" -LogStatus Info

        try {
            Set-CertPrivateKeyPermission -AccountName $ServiceAccount -Certificate $certificate -Permission Read
            Write-Log -LogText "`t$($uiLanguage.NoSpamProxyGwRolePermissionOk)" -LogStatus Success -Absatz
        }
        catch {
            Write-Log -LogText "t$($uiLanguage.NoSpamProxyGwRolePermissionError)." -LogStatus Error -Absatz
        }
    }
}
else {
    Write-Log -LogText $uiLanguage.NoSpamProxyGwRoleError -LogStatus Warning -Absatz
}

# Set new permissions to the private key of the selected certificate for the intranet role
Write-Log -LogText $uiLanguage.NoSpamProxyIntraRoleInfoText -LogStatus Info
If (get-service | Where-Object { $_.Name -eq $strNspIntranetRoleServiceName }) {
    
    #
    foreach ($ServiceAccount in $aNspIntranetRoleServiceAccounts) {
        
        Write-Log -LogText "`t$($uiLanguage.NoSpamProxyIntraRoleAccountInfoText1) '$($ServiceAccount)' $($uiLanguage.NoSpamProxyIntraRoleAccountInfoText2)" -LogStatus Info

        try {
            Set-CertPrivateKeyPermission -AccountName $ServiceAccount -Certificate $certificate -Permission Read
            Write-Log -LogText "`t$($uiLanguage.NoSpamProxyIntraRolePermissionOk)" -LogStatus Success -Absatz
        }
        catch {
            Write-Log -LogText "t$($uiLanguage.NoSpamProxyIntraRolePermissionError)" -LogStatus Error -Absatz
        }
    }
}
else {
    Write-Log -LogText $uiLanguage.NoSpamProxyIntraRoleError -LogStatus Warning -Absatz
}

# Set new permissions to the private key of the selected certificate for the webportal role
Write-Log -LogText $uiLanguage.NoSpamProxyWebPortalRoleInfoText -LogStatus Info
If (get-service | Where-Object { $_.Name -eq $strNspWebportalRoleServiceName }) {
    
    #
    foreach ($ServiceAccount in $aNspWebPortalRoleServiceAccounts) {
        
        Write-Log -LogText "`t$($uiLanguage.NoSpamProxyWebPortalRoleAccountInfoText1) '$($ServiceAccount)' $($uiLanguage.NoSpamProxyWebPortalRoleAccountInfoText2)" -LogStatus Info

        try {
            Set-CertPrivateKeyPermission -AccountName $ServiceAccount -Certificate $certificate -Permission Read
            Write-Log -LogText "`t$($uiLanguage.NoSpamProxyWebPortalRolePermissionOk)" -LogStatus Success -Absatz
        }
        catch {
       $_.Exception.Message
            Write-Log -LogText "`t$($uiLanguage.NoSpamProxyWebPortalRolePermissionError)" -LogStatus Error -Absatz
        }
    }
}
else {
    Write-Log -LogText $uiLanguage.NoSpamProxyWebPortalRoleError -LogStatus Warning -Absatz
}

#
Write-Log $uiLanguage.LocalComputerCertPrivateKeyInfo -LogStatus Info
