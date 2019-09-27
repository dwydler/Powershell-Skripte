<#
.SYNOPSIS
PRTG Sensor script to monitor a Veeam Backup & Replication environment

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

.PARAMETER PrtgDevice
Name des Servers, auf dem die NoSpamProxy Intranet Rolle installiert ist.

.PARAMETER VeeamBRJobName
Name des Jobs, der innerhalb von Veeam Backup & Replication abgefragt werden soll.

 
.INPUTS
None
 
.OUTPUTS
Output exit code and a description
 
.NOTES
File:           paessler-prtg_monitor-veeam-backupand-replication-job.ps1
Version:        1.1
Author:         Daniel Wydler
Creation Date:  10.03.2019, 10:54 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
10.03.2019, 10:54 Uhr  Initial community release
18.09.2019, 21:39 Uhr  Code base revised
19.09.2019, 00:11 Uhr  Added informations to the header
27.09.2019, 09:49 Uhr  Fixed query of JobId


.COMPONENT
Veeam Backup & Replication Powershell-Module

.LINK
www.vmbaggum.nl/2015/03/monitor-veeam-backup-jobs-with-prtg/
github.com/dwydler/Powershell-Skripte/blob/master/Paessler/PRTG/paessler-prtg_monitor-veeam-backupand-replication-job.ps1


.EXAMPLE
.\paessler-prtg_monitor-veeam-backupand-replication-job.ps1 -PrtgDevice "localhost" -VeeamBRJobName "Job1"
.\paessler-prtg_monitor-veeam-backupand-replication-job.ps1 "localhost" "Job1"
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
 
Param (
   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=0,
        Mandatory=$true
    )]
    [ValidateNotNullOrEmpty()]
   [string] $PrtgDevice,

   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=1,
        Mandatory=$true
    )]
    [ValidateNotNullOrEmpty()]
   [string] $VeeamBRJobName
)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $FunctionForInvokeCommand = ""

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Set-PrtgResult {
        
        Param (
		    [Parameter(Mandatory=$true, Position=0)]
            [ValidateNotNullOrEmpty()]
		    [System.Object] $obLocalVBRxSession
	    )

        [string] $strVeeamBackupJobResult = ""

        # Auswertung des letzten Backup Jobs
	    If ($obLocalVBRxSession.Result -eq "Success") {
            $strVeeamBackupJobResult = "0:Job erfolgreich ausgeführt am"
        }
        ElseIf ($obLocalVBRxSession.Result -eq "Warning") {
            $strVeeamBackupJobResult = "1:Job mit Warnungen ausgeführt am"
        }
	    ElseIf ($obLocalVBRxSession.Result -eq "Failed") {
            $strVeeamBackupJobResult = "2:Job fehlgeschlagen am"
        }
	    Else {
            $strVeeamBackupJobResult = "2:Der Job hat einen unbekannten Status."
        }

        # Zeitstempel anhängen
        $strVeeamBackupJobResult += " " + $obLocalVBRxSession.CreationTime.ToString("dd.MM.yyyy HH:mm")

        return $strVeeamBackupJobResult
    }

#------------------------------------------------------------[Modules]-------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Vorberreitung, um bestehende Funktionen an das Invoke Command zu übergeben
$FunctionForInvokeCommand = "function Set-PrtgResult { ${function:Set-PrtgResult} }"

# Nachstehende Befehle werden auf dem entfernen Computer ausgeführt
$QueryResult = Invoke-Command -Computername $PrtgDevice -Args $VeeamBRJobName, $FunctionForInvokeCommand -ScriptBlock {

    # Variablen übergeben
	param(
        [string] $strVeeamBackupJobName,
        [System.Object] $FunctionForInvokeCommand
    )

    # Bereitgestellte Funktion wird aufgerufen
    . ([ScriptBlock]::Create($FunctionForInvokeCommand))
    
    # Füge das Veeam Powershell SnapIn zu aktuellen Sitzung hinzu
    try {
        Add-PSSnapin -Name VeeamPSSnapIn
    }
    catch {
        return "2:Powershell - Veeam PSSnapIn konnte nicht geladen werden!"
    }

    # Überprüfung, ob es bei dem Jobname um ein Backup & Replication Objekt handelt
    if (Get-VBRJob -Name $strVeeamBackupJobName -ErrorAction SilentlyContinue) {

        # Auslesen des letzten Ausführungsergebnis vom dem angegebenen Veeam Backup Job
        $strVeeamBackupJobId = Get-VBRJob -Name $strVeeamBackupJobName | Select -ExpandProperty Id
        $obVBRSession = Get-VBRBackupSession | Select JobId, Result, CreationTime | Where-Object { $_.JobId -eq $strVeeamBackupJobId } | Sort -Descending -Property "CreationTime" | Select -First 1
     
        # Auswertung des Ausführungsergebnis. Rückgabewert entspricht dem notwendigen Format für PRTG
        if($obVBRSession) {
            Set-PrtgResult -obLocalVBRxSession $obVBRSession
        }
        else {
            return "1:Der Job ist bisher noch nie gelaufen."
        }
    }
    # Überprüfung, ob es bei dem Jobname um ein Backup & Replication Entpoint Objekt handelt.
    elseif (Get-VBREPJob -Name $strVeeamBackupJobName -ErrorAction SilentlyContinue) {

        # Auslesen des letzten Ausführungsergebnis vom dem angegebenen Veeam Backup Job
        $strVeeamBackupJobId = Get-VBREPJob -Name $strVeeamBackupJobName | Select -ExpandProperty Id
        $obVBREPSession = Get-VBREPSession | Select JobId, Result, CreationTime | Where-Object { $_.JobId -eq $strVeeamBackupJobId } | Sort -Descending -Property "CreationTime" | Select -First 1

        # Auswertung des Ausführungsergebnis. Rückgabewert entspricht dem notwendigen Format für PRTG
        if($obVBREPSession) {
            Set-PrtgResult -obLocalVBRxSession $obVBREPSession
        }
        else {
            return "1:Der Job ist bisher noch nie gelaufen."
        }
    }
    else {
        return "1:Es konnte kein Job mit dem Namen '$strVeeamBackupJobName' gefunden werden!"
    }
}

# String splitten
$exitcode = $QueryResult -Split(':')

# Ausgabe für PRTG
write-host $QueryResult

# Script mit entsprechenden Fehlercode beenden
exit $exitcode[0]

