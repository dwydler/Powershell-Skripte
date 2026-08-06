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
Author:         Daniel Wydler
Creation Date:  10.03.2019, 10:54 Uhr


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
    
    # Generate PRTG sensor result output
    $strXmlOutput = "<prtg>`n"
    $strXmlOutput += "`t<error>1</error>`n"
    $strXmlOutput += "`t<text>$PrtgErrorText</text>`n"
    $strXmlOutput += "</prtg>"

    # Output the contents of the variable
    $strXmlOutput

    exit
}

function Set-PrtgResult {
    Param (
        [Parameter(mandatory=$True,Position=0)]
        [string]$Channel,
    
        [Parameter(mandatory=$True,Position=1)]
        $Value,
    
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

### The following commands will be executed on the remote computer
try {
    $objQueryResult = Invoke-command -ComputerName $PrtgDevice -ArgumentList $VeeamBRJobName -ScriptBlock {

        # Declarations
        param(
            [string] $strVeeamBackupJobName
        )

        [string] $strErrorMessage = $null
        [string] $strTrace = $null
        

        # Add the Veeam Powershell Module to the current session
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

        # Check if the job name is a Computer Backup object.
        if (Get-VBRComputerBackupJob -Name $strVeeamBackupJobName  -ErrorAction SilentlyContinue) {

            # Read the last execution result of the specified Veeam backup job
            $strVeeamBackupJobId = Get-VBRComputerBackupJob -Name $strVeeamBackupJobName | Select-Object -ExpandProperty Id
            $obVBRSession = Get-VBRComputerBackupJobSession | Where-Object { $_.JobId -eq $strVeeamBackupJobId } | Sort-Object -Descending -Property "CreationTime" | Select-Object -First 1
        }

        # Check if the job name is a Backup & Replication Entpoint object.
        elseif (Get-VBREPJob -Name $strVeeamBackupJobName -ErrorAction SilentlyContinue) {

            # Read the last execution result of the specified Veeam backup job
            $strVeeamBackupJobId = Get-VBREPJob -Name $strVeeamBackupJobName | Select-Object -ExpandProperty Id
            $obVBRSession = Get-VBREPSession | Where-Object { $_.JobId -eq $strVeeamBackupJobId } | Sort-Object -Descending -Property "CreationTime" | Select-Object -First 1
        }

        # Check if the job name is a Backup & Replication object.
        elseif (Get-VBRJob -Name $strVeeamBackupJobName  -ErrorAction SilentlyContinue) {

            # Read the last execution result of the specified Veeam backup job
            $obVBRSession = Get-VBRBackupSession | Where-Object { $_.JobName -match "$strVeeamBackupJobName" } | Sort-Object -Descending -Property "CreationTime" | Select-Object -First 1
        }

        # Check if the job name is a Backup & Replication Tape object
        elseif (Get-VBRTapeJob -Name $strVeeamBackupJobName -ErrorAction SilentlyContinue) {

            # Read the last execution result of the specified Veeam backup job
            $strVeeamBackupJobId = Get-VBRTapeJob -Name $strVeeamBackupJobName | Select-Object -ExpandProperty Id
            $obVBRSession = Get-VBRBackupSession | Where-Object { $_.JobId -eq $strVeeamBackupJobId } | Sort-Object -Descending -Property "CreationTime" | Select-Object -First 1
        }
        # Matches if all previous queries have failed
        else {

            # Save text of the error message in the variable
            $strErrorMessage = "Keinen Veeam Job mit dem Namen `"$strVeeamBackupJobName`" gefunden!"

            # Create a data object
            $objReturnData = "" | Select-Object -Property strErrorMessage, strTrace
            $objReturnData.strErrorMessage = $strErrorMessage
            $objReturnData.strTrace = $strTrace
            
            # Return the content of the variable to the main program
            return $objReturnData
        }

        # Check if a matching Veeam backup session was found
        # If no session exists, return an error message.
        # Otherwise, create a return object containing the relevant backup session data.
        if ($null -eq $obVBRSession) {

            # Save text of the error message in the variable
            $strErrorMessage = "Veeam Job gefunden. Job hat keine historischen Daten!"

            # Create a data object
            $objReturnData = "" | Select-Object -Property strErrorMessage
            $objReturnData.strErrorMessage = $strErrorMessage

            return $objReturnData
        }        
        else {
            # Create a data object with the relevant data of the Veeam job
            $obCustomReturn = New-Object -TypeName System.Object
            $obCustomReturn | Add-Member -MemberType NoteProperty -Name "Result" -Value $obVBRSession.Result.ToString()
            $obCustomReturn | Add-Member -MemberType NoteProperty -Name "AuxData" -Value $obVBRSession.AuxData
            $obCustomReturn | Add-Member -MemberType NoteProperty -Name "CreationTime" -Value $obVBRSession.CreationTime
            $obCustomReturn | Add-Member -MemberType NoteProperty -Name "EndTime" -Value $obVBRSession.EndTime
            
            if ($obVBRSession.JobType -eq 'VmTapeBackup') {
                $obCustomReturn | Add-Member -MemberType NoteProperty -Name "BackupSize" -Value $obVBRSession.SessionInfo.BackUpTotalSize
            }
            elseif ($obVBRSession.JobType -eq 'Backup') {
                $obCustomReturn | Add-Member -MemberType NoteProperty -Name "BackupSize" -Value $obVBRSession.SessionInfo.BackedUpSize
            }
        }
        
        # Return the content of the variable to the main program
        return $obCustomReturn

    } -ErrorAction Stop
}
### If the target server cannot be connected (wrong DNS name, wrong username/password, insufficient permissions), the respective error message is displayed.
catch {
    # Change the sensor status to error and output a custom error message
    Set-PrtgError "$($_.Exception.Message)"
}


### If an error occurred set prtg sensor to error state
### Else no error occurred the return values will be processed
If($objQueryResult.strErrorMessage) {

    # Change the sensor status to error and output a custom error message
    Set-PrtgError $objQueryResult.strErrorMessage
}
else {
   
    # Evaluating the status of the job and converting it into the respective PRTG sensor statues
    switch ($objQueryResult.Result) {            
            
        "Success" { $intVeeamBackupJobResult = 0 }
        "Warning" { $intVeeamBackupJobResult = 1 }
        "Failed"  { $intVeeamBackupJobResult = 2 }

        "None"    { $intVeeamBackupJobResult = 0 }
        Default   { $intVeeamBackupJobResult = 1 }           
    } 

    # Assign metadata of the Veeam backup job to the variable
    [xml] $xmlVeeamBackupJobAuxDetails = $objQueryResult.AuxData

    # Generate PRTG sensor result output
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

    # Output the contents of the variable
    $xmlOutput
}
