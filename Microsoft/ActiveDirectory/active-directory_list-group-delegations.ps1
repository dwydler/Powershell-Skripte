<#
.SYNOPSIS
Übersicht aller Delegierungen im Active Directory.

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION
 
.PARAMETER <Parameter_Name>
<Brief description of parameter input required. Repeat this attribute if required>
 
.INPUTS
None
 
.OUTPUTS
None
 
.NOTES
File:           active-directory_list-delegations.ps1
Version:        1.0
Author:         Daniel Wydler
Creation Date:  10.03.2019, 12:45 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
10.03.2019, 12:45 Uhr  Initial community release
07.09.2019, 16:00 Uhr  Code base revised


.COMPONENT
Active Directory PowerShell Module

.LINK
https://github.com/dwydler/Powershell-Skripte/blob/master/Microsoft/ActiveDirectory/active-directory_list-group-delegations.ps1

.EXAMPLE
.\active-directory_list-delegations.ps1
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

#
[string] $strADDomainDN = ""
[string] $strADDomainNetBIOSName = ""
[string] $strOrganizationUnit = ""
[array] $arrOrganizationUnits = @()



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
            mandatory=$True,
            Position=0
        )]
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

function ReadDelegation {
    
    Param (
        [Parameter(
            mandatory=$True,
            Position=0
        )]
        [string] $AdGroupName
    )

    $SearchResults = New-Object System.Collections.Generic.List[object]


    Write-Log "Überprüfe, ob die Gruppe '$AdGroupName' im Active Directory exstiert." -LogStatus Info
    try {
        Get-ADGroup -Identity $AdGroupName | Out-Null
        Write-Log -LogText "Die Gruppe '$AdGroupName' wurde gefunden." -LogStatus Success -Absatz
    }
    catch {
        Write-Log -LogText "Die Gruppe '$AdGroupName' wurde nicht gefunden!" -LogStatus Error
        exit
    }
######

    Write-Log -LogText "Active Directory wird durchsucht..." -LogStatus Info
    ForEach ($strOrganizationUnit in $arrOrganizationUnits) {
 
        Write-Log -LogText $strOrganizationUnit -LogStatus Info

        # Auslesen möglicher Delegierungen 
        (Get-Acl -Path "AD:\$strOrganizationUnit").Access | Select IdentityReference, IsInherited, ActiveDirectoryRights | `
            ? IdentityReference -eq $("$strADDomainNetBIOSName\$AdGroupName") | ? IsInherited -eq $false | ForEach {
 
            $obj = New-Object Psobject -Property @{
	            "Organisationseinheit" = $strOrganizationUnit
	            "Gruppe" = $_.IdentityReference
                "Vererbt" = $_.IsInherited
                "Rechte" = $_.ActiveDirectoryRights
            }

            $SearchResults.add($obj)

            Write-Log -LogText "`tGruppe: $($_.IdentityReference)" -LogStatus Info
            Write-Log -LogText "`tVererbt: $($_.IsInherited)" -LogStatus Info
            Write-Log -LogText "`tRechte: $($_.ActiveDirectoryRights)" -LogStatus Info 
        }
    }
    Write-Log -LogText "Die Suche im Active Directory ist abgeschlossen." -LogStatus Success -Absatz

    return $SearchResults

}

#------------------------------------------------------------[Modules]-------------------------------------------------------------

LoadModule -ModuleName "ActiveDirectory"

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Log -LogText "Wechsele das Arbeitsverzeichnis..." -LogStatus Info
WorkingDir

Write-Log -LogText "Auslesen des DistinguishedName der Active Directory Domäne" -LogStatus Info
$strADDomainDN = (Get-ADDomain).DistinguishedName
 
Write-Log -LogText "Auslesen des NetBIOSName der Active Directory Domäne" -LogStatus Info
$strADDomainNetBIOSName = (Get-ADDomain).NetBIOSName
 
Write-Log -LogText "Auslesen aller Organisationseinheiten" -LogStatus Info -Absatz
$arrOrganizationUnits = (Get-ADOrganizationalUnit -Filter * -SearchBase $strADDomainDN).DistinguishedName | Sort-Object


# Auf der Funktion und Übergabe des Gruppennamen. Die Rückgabe bzw. das Result wird als GridView angezeigt
ReadDeligation -AdGroupName "a" | Select-Object -Property Organisationseinheit, Gruppe, Vererbt, Rechte | Out-Gridview -Title "Suchergebnis aus dem Active Diretory $strADDomainNetBIOSName"

ReadDeligation -AdGroupName "b" | Select-Object -Property Organisationseinheit, Gruppe, Vererbt, Rechte | Out-Gridview -Title "Suchergebnis aus dem Active Diretory $strADDomainNetBIOSName"

ReadDeligation -AdGroupName "c" | Select-Object -Property Organisationseinheit, Gruppe, Vererbt, Rechte | Out-Gridview -Title "Suchergebnis aus dem Active Diretory $strADDomainNetBIOSName"
