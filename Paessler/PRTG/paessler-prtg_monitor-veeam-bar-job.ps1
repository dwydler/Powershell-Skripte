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
File:           paessler-prtg_monitor-veeam-bar-job.ps1
Version:        1.3
Author:         Daniel Wydler
Creation Date:  10.03.2019, 10:54 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
10.03.2019, 10:54 Uhr  Initial community release
18.09.2019, 21:39 Uhr  Code base revised
19.09.2019, 00:11 Uhr  Added informations to the header
27.09.2019, 09:49 Uhr  Fixed query of JobId
31.01.2021, 12:19 Uhr  Added parameter to Set-PrtgResult
31.01.2021, 13:45 Uhr  Fixed if query in Set-PrtgResult
31.01.2021, 17:23 Uhr  Code base revised
27.03.2021, 19:45 Uhr  Added Connection test for remote computer
27.03.2021, 20:03 Uhr  Fixed error handling in Invoke-Command
27.03.2021, 20:22 Uhr  Fixed query for computer backup jobs
28.03.2021, 18;44 Uhr  Fixed query for computer backup jobs
28.03.2021, 18:54 Uhr  Fixed evaluation of job status
06.01.2022, 16:33 Uhr  Changed Veeam PsSnapIn to Import-Module
28.03.2022, 11:20 Uhr  Added Support for Tape Jobs (Thanks to offline4ever)
28.03.2022, 11:21 Uhr  Fixed Dashes
28.03.2022, 11:28 Uhr  Rename file name of the script

.COMPONENT
Veeam Backup & Replication Powershell-Module

.LINK
www.vmbaggum.nl/2015/03/monitor-veeam-backup-jobs-with-prtg/
github.com/dwydler/Powershell-Skripte/blob/master/Paessler/PRTG/paessler-prtg_monitor-veeam-bar-job.ps1


.EXAMPLE
.\paessler-prtg_monitor-veeam-bar-job.ps1.ps1 -PrtgDevice "localhost" -VeeamBRJobName "Job1"
.\paessler-prtg_monitor-veeam-bar-job.ps1.ps1 "localhost" "Job1"
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

[string] $strXmlOutput = ""
[System.Object] $objQueryResult = $null

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
    
        [Parameter(mandatory=$False,Position=2)]
        [string]$Unit = "Custom",

        [Parameter(mandatory=$False)]
        [string]$CustomUnit,

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
        [ValidateSet('Second','Minute','Hour','Day')]
        [string]$SpeedTime,
    
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
    if ( ($Unit -eq "Custom") -and ($CustomUnit) ) {
        $Result += "`t`t<customunit>$CustomUnit</customunit>`n"
    }
    
    if (!($Value -match "^\d+$")) { $Result += "`t`t<float>1</float>`n" }
    if ($Mode)                    { $Result += "`t`t<mode>$Mode</mode>`n" }
    if ($MaxWarn)                 { $Result += "`t`t<limitmaxwarning>$MaxWarn</limitmaxwarning>`n"; $LimitMode = $true }
    if ($MinWarn)                 { $Result += "`t`t<limitminwarning>$MinWarn</limitminwarning>`n"; $LimitMode = $true }
    if ($MaxError)                { $Result += "`t`t<limitmaxerror>$MaxError</limitmaxerror>`n"; $LimitMode = $true }
    if ($WarnMsg)                 { $Result += "`t`t<limitwarningmsg>$WarnMsg</limitwarningmsg>`n"; $LimitMode = $true }
    if ($ErrorMsg)                { $Result += "`t`t<limiterrormsg>$ErrorMsg</limiterrormsg>`n"; $LimitMode = $true }
    if ($LimitMode)               { $Result += "`t`t<limitmode>1</limitmode>`n" }
    if ($SpeedSize)               { $Result += "`t`t<speedsize>$SpeedSize</speedsize>`n" }
    if ($VolumeSize)              { $Result += "`t`t<volumesize>$VolumeSize</volumesize>`n" }
    if ($SpeedTime)               { $Result += "`t`t<speedtime>$SpeedTime</speedtime>`n" }
    if ($DecimalMode)             { $Result += "`t`t<decimalmode>$DecimalMode</decimalmode>`n" }
    if ($Warning)                 { $Result += "`t`t<warning>1</warning>`n" }
    if ($ValueLookup)             { $Result += "`t`t<ValueLookup>$ValueLookup</ValueLookup>`n" }
    if (!($ShowChart))            { $Result += "`t`t<showchart>0</showchart>`n" }
    
    $Result += "`t</result>`n"
    
    return $Result
}


#------------------------------------------------------------[Modules]-------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

### Check if the remote device is reachable over PowerShell Remoting
If (-not (Test-NetConnection $PrtgDevice -port 5985 -InformationLevel Quiet)) {
    Set-PrtgError "Gerät nicht erreichbar. PowerShell Remoting ativiert?"
}


### The following commands will be executed on the remote computer
$objQueryResult = Invoke-command -ComputerName $PrtgDevice -Args $VeeamBRJobName -ScriptBlock {

    ### Declarations
    param(
        [string] $strVeeamBackupJobName
    )

    [array] $aVBRSession=@()
    [string] $strErrorMessage = $null
    [string] $strTrace = $null
    

    ### Fuege das Veeam Powershell Module zu aktuellen Sitzung hinzu
    try {
        Import-Module Veeam.Backup.PowerShell -ErrorAction Stop 
    }
    catch {
        $strErrorMessage = $_.Exception.Message

        $objReturnData = "" | Select-Object -Property strErrorMessage, strTrace
        $objReturnData.strErrorMessage = $strErrorMessage
        $objReturnData.strTrace = $strTrace
        
        return $objReturnData
    }

    ### Ueberpruefung, ob es bei dem Jobname um ein Computer Backup Objekt handelt.
    if (Get-VBRComputerBackupJob -Name $strVeeamBackupJobName  -ErrorAction SilentlyContinue) {

        ### Auslesen des letzten Ausfuehrungsergebnis vom dem angegebenen Veeam Backup Job
        $strVeeamBackupJobId = Get-VBRComputerBackupJob -Name $strVeeamBackupJobName | Select -ExpandProperty Id
        
        $aVBRSession = Get-VBRComputerBackupJobSession
        $obVBRSession = $aVBRSession | Where-Object { $_.JobId -eq $strVeeamBackupJobId } | Sort -Descending -Property "CreationTime" | Select -First 1
    }

    # Ueberpruefung, ob es bei dem Jobname um ein Backup & Replication Entpoint Objekt handelt.
    elseif (Get-VBREPJob -Name $strVeeamBackupJobName -ErrorAction SilentlyContinue) {
        $strVeeamBackupJobId = Get-VBREPJob -Name $strVeeamBackupJobName | Select -ExpandProperty Id
        $obVBRSession = Get-VBREPSession | Where-Object { $_.JobId -eq $strVeeamBackupJobId } | Sort -Descending -Property "CreationTime" | Select -First 1
    }

    ### Ueberpruefung, ob es bei dem Jobname um ein Backup & Replication Objekt handelt.
    elseif (Get-VBRJob -Name $strVeeamBackupJobName  -ErrorAction SilentlyContinue) {

        ### Auslesen des letzten Ausfuehrungsergebnis vom dem angegebenen Veeam Backup Job
        $strVeeamBackupJobId = Get-VBRJob -Name $strVeeamBackupJobName | Select -ExpandProperty Id
        $obVBRSession = Get-VBRBackupSession | Where-Object { $_.JobId -eq $strVeeamBackupJobId } | Sort -Descending -Property "CreationTime" | Select -First 1
    }

	### Ueberpruefung, ob es bei dem Jobname um ein Backup & Replication Tape Objekt handelt.
	elseif (Get-VBRTapeJob -Name $strVeeamBackupJobName -ErrorAction SilentlyContinue) {

		### Auslesen des letzten Ausfuehrungsergebnis vom dem angegebenen Veeam Backup Job
		$strVeeamBackupJobId = Get-VBRTapeJob -Name $strVeeamBackupJobName | Select -ExpandProperty Id
		#Get-VBRTapeBackup nicht mehr nutzen -> WARNUNG: This cmdlet is obsolete and no longer supported
		#See: https://helpcenter.veeam.com/docs/backup/powershell/get-vbrtapebackup.html?ver=110
		$obVBRSession = [veeam.backup.core.cbackupsession]::GetByJob($strVeeamBackupJobId) | Sort CreationTime -Descending | select -First 1
	}
    ### If no previous condition matched
    else {
        $strErrorMessage = "Keinen Veeam Job mit dem Namen `"$strVeeamBackupJobName`" gefunden!"

        $objReturnData = "" | Select-Object -Property strErrorMessage, strTrace
        $objReturnData.strErrorMessage = $strErrorMessage
        $objReturnData.strTrace = $strTrace
        
        return $objReturnData
    }

	$obCustomReturn = New-Object -TypeName System.Object
	$obCustomReturn | Add-Member -MemberType NoteProperty -Name "Result" -Value $obVBRSession.Result.ToString()
	$obCustomReturn | Add-Member -MemberType NoteProperty -Name "AuxData" -Value $obVBRSession.AuxData
	$obCustomReturn | Add-Member -MemberType NoteProperty -Name "CreationTime" -Value $obVBRSession.CreationTime
	$obCustomReturn | Add-Member -MemberType NoteProperty -Name "EndTime" -Value $obVBRSession.EndTime
	if ($obVBRSession.JobType -eq 'VmTapeBackup') {
		$obCustomReturn | Add-Member -MemberType NoteProperty -Name "BackupSize" -Value $obVBRSession.SessionInfo.BackUpTotalSize
	} elseif ($obVBRSession.JobType -eq 'Backup') {
		$obCustomReturn | Add-Member -MemberType NoteProperty -Name "BackupSize" -Value $obVBRSession.SessionInfo.BackedUpSize
	}
	
    ###
    return $obCustomReturn
}


### If an error occurred set prtg sensor to error state
### Else no error occurred the return values will be processed
If($objQueryResult.strErrorMessage) {
    Set-PrtgError $objQueryResult.strErrorMessage
}
else {
   
    ###
    switch ($objQueryResult.Result) {            
            
        "Success" { $intVeeamBackupJobResult = 0 }
        "Warning" { $intVeeamBackupJobResult = 1 }
        "Failed"  { $intVeeamBackupJobResult = 2 }

        "None"    { $intVeeamBackupJobResult = 0 }
        Default   { $intVeeamBackupJobResult = 1 }           
    } 

    ### Metadata des Veeam Backup Jobs in eine Variable einlesen
    [xml] $xmlVeeamBackupJobAuxDetails = $objQueryResult.AuxData

    ### Generate PRTG Output
    $xmlOutput = "<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes""?>`n"
    $xmlOutput += "<prtg>`n"

    $xmlOutput += Set-PrtgResult -Channel "Job Result" -Value $intVeeamBackupJobResult -Unit Count -ShowChart -WarnMsg "Job wurde mit Warnungen ausgefuehrt." -ErrorMsg "Job wurde mit Fehler ausgefuehrt." -MaxWarn 0 -MaxError 1

    if ($objQueryResult.EndTime -and $objQueryResult.CreationTime) {
    $xmlOutput += Set-PrtgResult -Channel "LaufzeitHour" -Value $( ($objQueryResult.EndTime - $objQueryResult.CreationTime).Hours)  -CustomUnit "Std." -ShowChart
    $xmlOutput += Set-PrtgResult -Channel "LaufzeitMinutes" -Value $( ($objQueryResult.EndTime - $objQueryResult.CreationTime).Minutes)  -CustomUnit "Min." -ShowChart
    $xmlOutput += Set-PrtgResult -Channel "LaufzeitSeconds" -Value $( ($objQueryResult.EndTime - $objQueryResult.CreationTime).Seconds)  -CustomUnit "Sek." -ShowChart
    }
    if ($objQueryResult.BackupSize) {
        $xmlOutput += Set-PrtgResult -Channel "Job BackupSize" -Value ($objQueryResult.BackupSize) -VolumeSize GigaByte -ShowChart -DecimalMode "Auto"
    }
    if ($xmlVeeamBackupJobAuxDetails.AuxData.CBackupstats.DataSize) {
        $xmlOutput += Set-PrtgResult -Channel "Job DataSize" -Value ($xmlVeeamBackupJobAuxDetails.AuxData.CBackupstats.DataSize) -VolumeSize GigaByte -ShowChart
    }
    if ($xmlVeeamBackupJobAuxDetails.AuxData.CBackupstats.DedupRatio) {
        $xmlOutput += Set-PrtgResult -Channel "Job DedupRatio" -Value ($xmlVeeamBackupJobAuxDetails.AuxData.CBackupstats.DedupRatio) -ShowChart
    }
    if ($xmlVeeamBackupJobAuxDetails.AuxData.CBackupstats.CompressRatio) {
    $xmlOutput += Set-PrtgResult -Channel "Job CompressRatio" -Value ($xmlVeeamBackupJobAuxDetails.AuxData.CBackupstats.CompressRatio) -ShowChart
    }
    if ($objQueryResult.CreationTime) {
        $xmlOutput += "`t<text>Start: "+ $(get-date $objQueryResult.CreationTime -Format "dd.MM.yyyy HH:mm:ss") +", Ende: "+ $(get-date $objQueryResult.EndTime -Format "dd.MM.yyyy HH:mm:ss") +"</text>`n"
    }
    else {
        $xmlOutput += "`t<text>Job ist bisher nicht gelaufen.</text>`n"
    }
    $xmlOutput += "</prtg>"

    ### Return Xml
    $xmlOutput
}
