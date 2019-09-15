<#
.SYNOPSIS
Dieses Skript kann den Pfad für Profile ändern

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
Bei Migrationen von Dateiservern werden meist auch die servergespeicherten Profile umgezogen.
Damit verbunden ist, dass in den Benutzerkonten manuell der Pfad zum servergespeicherten Benutzer- und RDS-Profi angepasst werden muss.
Mit diesem Skript könn beide Felder im Benutzerkonto automatisch angepasst werden.

Wird den Funktionen kein DistinguishedName übergeben, wird das Skript auf die ganze Domäne angewendet.
Werden die Funktionen mit dem Paramter -Testing aufgerufen, erfolgt keine Änderung der Pfade im Benutzerkonto.
 
.PARAMETER <Parameter_Name>
<Brief description of parameter input required. Repeat this attribute if required>
 
.INPUTS
None
 
.OUTPUTS
None
 
.NOTES
File:           windows-server_migrate-roaming-profiles-paths.ps1
Version:        1.1
Author:         Daniel Wydler
Creation Date:  10.03.2019, 12:45 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
10.03.2019, 12:45 Uhr  Initial community release
15.09.2019, 11:07 Uhr  Code base revised
15.09.2019, 14:08 Uhr  separate functions for user/rds profile path


.COMPONENT
Active Directory PowerShell Module

.LINK
https://github.com/dwydler/Powershell-Skripte/blob/master/Microsoft/WindowsServer/windows-server_migrate-roaming-profiles-paths.ps1

.EXAMPLE
.\windows-server_migrate-roaming-profiles-paths.ps1
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

### function Write-Log
[string] $strLogfilePath = "C:\Temp"
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
[string] $strLogfileNamePrefix = "Log_"
[string] $strLogfileName = $($strLogfileNamePrefix + $strLogfileDate + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName


###


#-----------------------------------------------------------[Functions]------------------------------------------------------------

function WorkingDir {
    param (
         [parameter(
            Mandatory=$false,
            Position=0
          )]
        [switch] $Debugging
    )

    # Splittet aus dem vollständigen Dateipfad den Verzeichnispfad heraus
    # Beispiel: C:\Temp\Unbenannt2.ps1 -> C:\Temp
    [string] $strWorkingdir = Split-Path $MyInvocation.PSCommandPath -Parent

    # Wenn Variable wahr ist, gebe Text aus.
    if ($Debugging) {
        Write-Host "[DEBUG] PS $strWorkingdir`>" -ForegroundColor Gray
    }

    # In das Verzeichnis wechseln
    cd $strWorkingdir
}

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$true,
            Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $LogText = "",

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Info','Success','Warning','Error')]
        [string] $LogStatus= "Info",

        [Parameter(Mandatory=$false)]
        [switch] $Absatz,

        [Parameter(Mandatory=$false)]
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
        $strLogFileHeader = "$("#" * 75)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Skript:", "$($MyInvocation.ScriptName)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Startzeit:", "$(Get-Date -Format "dd.MM.yyyy HH:mm:ss")`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Startzeit:", "$(Get-Date -Format "dd.MM.yyyy HH:mm:ss")`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Ausführendes Konto:", "$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Computername:", "$env:COMPUTERNAME`n"
        $strLogFileHeader += "$("#" * 75)`n"

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

function LoadModule {
    Param (
        [Parameter(
            Mandatory=$True,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        [string] $ModuleName
    )

    if (Get-Module -ListAvailable -Name $ModuleName ) {
    Write-Log -LogText "Das Modul '$ModuleName' existiert." -LogStatus Info

        if (Get-module $ModuleName) {
            Write-Log -LogText "Das Modul '$ModuleName' ist bereits geladen." -LogStatus Info -Absatz
        }
        else {
            Write-Log -LogText "Das Modul '$ModuleName' wurde eingebunden." -LogStatus Success -Absatz
            Import-Module $ModuleName
        }
    } 
    else {
        Write-Log -LogText "Das Modul '$ModuleName' existiert nicht!" -LogStatus Error
        exit
    }
}

function ChangeUserProfilePath {
    Param (
        [Parameter(
            Mandatory=$True,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        [string] $OldUserProfilePath,
        
        [Parameter(
            Mandatory=$True,
            Position=1
        )]
        [ValidateNotNullOrEmpty()]
        [string] $NewUserProfilePath,

        [Parameter(
            Mandatory=$False
        )]
        [string] $OrganisationDN,

        [Parameter(
            Mandatory=$False
        )]
        [switch] $Testing
    )
    
    # Declarations
    [array] $arrUsers = @()

    Write-Log -LogText "###" -LogStatus Info
    Write-Log -LogText "### Ändere '$OldUserProfilePath' zu '$NewUserProfilePath'; $OrganisationDN" -LogStatus Info
    Write-Log -LogText "###" -LogStatus Info

    # Falls keine Organisationseinheit übergeben wird, wird die ganze Domäne genommen.
    if ($OrganisationDN -eq "") {

        Write-Log "Keine Organisationseinheit angeben. Nehme die ganze Domäne!" -LogStatus Warning
        $OrganisationDN = (Get-ADDomain).DistinguishedName
    }
    else {
        Write-Log -LogText "Überprüfe, ob der DN der Organisationseinheit existiert" -LogStatus Info
        try {
            Get-ADOrganizationalUnit -Identity $OrganisationDN | Out-Null
            Write-Log -LogText "Die angegebene Organisationseinheit wurde gefunden." -LogStatus Success
        }
        catch {
            Write-Log -LogText "Die angegebene Organisationseinheit wurde nicht gefunden!" -LogStatus Error
            if ( -not ($Testing) ) {
                exit
            }
        }
    }

    Write-Log "Überprüfe den biserigen Pfad der servergespeicherten Benutzerprofile." -LogStatus Info
    if(Test-Path -Path $OldUserProfilePath) {
        Write-Log -LogText "Angegebener Pad '$OldUserProfilePath' wurde gefunden." -LogStatus Success
    }
    else {
        Write-Log -LogText "Angegebener Pad '$OldUserProfilePath' exstiert nicht oder zu wenige Rechte!" -LogStatus Error
        if ( -not ($Testing) ) {
            exit
        }
    }

    Write-Log "Überprüfe den neuen Pfad der servergespeicherten Benutzerprofile." -LogStatus Info
    if(Test-Path -Path $NewUserProfilePath) {
        Write-Log -LogText "Angegebener Pad '$NewUserProfilePath' wurde gefunden." -LogStatus Success
    }
    else {
        Write-Log -LogText "Angegebener Pad '$NewUserProfilePath' exstiert nicht oder zu wenige Rechte!" -LogStatus Error
        if ( -not ($Testing) ) {
            exit
        }
    }

    Write-Log -LogText "Alle Benutzer im Active Directory auslesen, welche dem Muster des Profilpfades entsprechen." -LogStatus Info
    $arrUsers = Get-ADUser -SearchBase $OrganisationDN -Filter "*" -Properties ProfilePath | Select-Object ProfilePath, SamAccountName | Where-Object { $_.ProfilePath -like "$OldUserProfilePath*" } | Sort-Object

    if($arrUsers.Count -eq 0) {
        Write-Log -LogText "Keine Benutzer gefunden, welche dem bisherigen Pfad '$($OldUserProfilePath)' entsprechen!" -LogStatus Warning
    }
    else {
        foreach ($user in $arrUsers) {

            Write-Log -LogText "Benutzerkonto '$($user.SamAccountName)' ist an der Reihe." -LogStatus Info

            try {
                if ( -not ($Testing) ) {
                    Set-ADUser $user.SamAccountName -ProfilePath "$NewUserProfilePath\$($user.SamAccountName)"
                }
                Write-Log -LogText "Der Pfad wurde erfolgreich geändert." -LogStatus Success
            }
            catch {
                Write-Log -LogText "Beim Ändern des Pfades ist ein Fehler aufgetreten!" -LogStatus Error
            }
        }
    }
    Write-Log -LogText "Vorgang erfolgreich abgeschlossen." -LogStatus Success -Absatz
}

function ChangeRdsProfilePath {
    Param (
        [Parameter(
            Mandatory=$True,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        [string] $OldRdsProfilePath,
        
        [Parameter(
            Mandatory=$True,
            Position=1
        )]
        [ValidateNotNullOrEmpty()]
        [string] $NewRdsProfilePath,

        [Parameter(
            Mandatory=$False
        )]
        [string] $OrganisationDN,

        [Parameter(
            Mandatory=$False
        )]
        [switch] $Testing
    )
    
    # Declarations
    [array] $arrUsers = @()

    Write-Log -LogText "###" -LogStatus Info
    Write-Log -LogText "### Ändere '$OldRdsProfilePath' zu '$NewRdsProfilePath'; $OrganisationDN" -LogStatus Info
    Write-Log -LogText "###" -LogStatus Info

    # Falls keine Organisationseinheit übergeben wird, wird die ganze Domäne genommen.
    if ($OrganisationDN -eq "") {

        Write-Log "Keine Organisationseinheit angeben. Die Ganze Domäne wird durchsucht!" -LogStatus Warning -Absatz
        $OrganisationDN = (Get-ADDomain).DistinguishedName  
    }
    else {
        Write-Log -LogText "Überprüfe, ob der DN der Organisationseinheit existiert" -LogStatus Info
        try {
            Get-ADOrganizationalUnit -Identity $OrganisationDN | Out-Null
            Write-Log -LogText "Die angegebene Organisationseinheit wurde gefunden." -LogStatus Success -Absatz
        }
        catch {
            Write-Log -LogText "Die angegebene Organisationseinheit wurde nicht gefunden!" -LogStatus Error -Absatz
            if ( -not ($Testing) ) {
            exit
        }
        }
    }

    Write-Log "Überprüfe den biserigen Pfad der servergespeicherten RDS Benutzerprofile." -LogStatus Info
    if(Test-Path -Path $OldRdsProfilePath) {
        Write-Log -LogText "Angegebener Pad '$OldRdsProfilePath' wurde gefunden." -LogStatus Success -Absatz
    }
    else {
        Write-Log -LogText "Angegebener Pad '$OldRdsProfilePath' exstiert nicht oder zu wenige Rechte!" -LogStatus Error -Absatz
        if ( -not ($Testing) ) {
            exit
        }
    }

    Write-Log "Überprüfe den neuen Pfad der servergespeicherten RDS Benutzerprofile." -LogStatus Info
    if(Test-Path -Path $NewRdsProfilePath) {
        Write-Log -LogText "Angegebener Pad '$NewRdsProfilePath' wurde gefunden." -LogStatus Success -Absatz
    }
    else {
        Write-Log -LogText "Angegebener Pad '$NewRdsProfilePath' exstiert nicht oder zu wenige Rechte!" -LogStatus Error -Absatz
        if ( -not ($Testing) ) {
            exit
        }
    }

    Write-Log -LogText "Alle Benutzer im Active Directory auslesen, welche dem Muster des Profilpfades entsprechen." -LogStatus Info
    $arrUsers = Get-ADUser -SearchBase $OrganisationDN -Filter "*" | ForEach-Object { `
                    $_ | Add-Member -Membertype NoteProperty -Name TerminalServicesProfilePath -Value ( ( ([ADSI]"LDAP://$($_.DistinguishedName)").TerminalServicesProfilePath) | Out-String) -Force -PassThru } | `
                    Select-Object DistinguishedName, SamAccountName, TerminalServicesProfilePath | Where-Object  { $_.TerminalServicesProfilePath -like "$OldRdsProfilePath*" } | Sort-Object
    

    if($arrUsers.Count -eq 0) {
        Write-Log -LogText "Keine Benutzerkonten gefunden, bei denen der Pfad '$($OldRdsProfilePath)' hinterlegt ist!" -LogStatus Warning
    }
    else {
        foreach ($user in $arrUsers) {

            Write-Log -LogText "Benutzerkonto '$($user.SamAccountName)' ist an der Reihe." -LogStatus Info

            try {
                if ( -not ($Testing) ) {
                    $ADSI = [ADSI]"LDAP://$($user.DistinguishedName)"
                    $ADSI.InvokeSet('TerminalServicesProfilePath',"$NewRdsProfilePath\$($user.SamAccountName)")
                    $ADSI.SetInfo()
                }
                
                Write-Log -LogText "Der Pfad wurde erfolgreich geändert." -LogStatus Success
            }
            catch {
                Write-Log -LogText "Beim Ändern des Pfades ist ein Fehler aufgetreten!" -LogStatus Error
            }
        }
    }
    Write-Log -LogText "Vorgang erfolgreich abgeschlossen." -LogStatus Success -Absatz
}

#------------------------------------------------------------[Modules]-------------------------------------------------------------

LoadModule -ModuleName "ActiveDirectory"

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Log -LogText "Wechsele das Arbeitsverzeichnis..." -LogStatus Info -Absatz
WorkingDir


ChangeUserProfilePath -OldUserProfilePath "\\filer01\profile" -NewUserProfilePath "\\filer02\profile" -Testing
ChangeUserProfilePath -OldUserProfilePath "\\filer02\profile" -NewUserProfilePath "\\filer03\profile" -OrganisationDN "OU=Benutzer,DC=lab02,DC=wydler,DC=eu" -Testing

ChangeRdsProfilePath -OldRdsProfilePath "\\filer01\rdsprofile" -NewRdsProfilePath "\\filer02\rdsprofile" -Testing
ChangeRdsProfilePath -OldRdsProfilePath "\\filer02\rdsprofile" -NewRdsProfilePath "\\filer03\rdsprofile" -OrganisationDN "OU=Benutzer,DC=lab02,DC=wydler,DC=eu" -Testing
