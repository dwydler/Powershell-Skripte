#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strLogfilePath = "C:\Temp"
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm"
[string] $strLogfileName = ("Log_" + $strLogfileDate + "_"+ $env:USERDOMAIN + "_" + $env:USERNAME + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string] $LogText = "",

        [Parameter(Mandatory=$true)]
        [ValidateRange(0,3)]
        [int] $LogLevel=0
    )

	[string] $strLogdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    [array] $aDebugLevel = @("INFO   ", "WARNING", "ERROR  ", "SUCCESS")
    [array] $aDebugTextColor = @("White", "Yellow", "Red", "Green")

    $LogText = "$strLogdate - $($aDebugLevel[$LogLevel]) - $LogText"

    Write-Host $LogText -ForegroundColor $aDebugTextColor[$LogLevel]
    "$LogText" | Out-File -FilePath $strLogfile -Append

}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Log -LogText "Das Verzeichnis $strVmWareBackupPath\$strVmWareBackupFolder wird angelegt..." -LogLevel 0
