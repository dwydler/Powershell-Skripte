[string] $strHeadline = "{0,-25} {1,10}" -f "Benutzername","AnyDeskID"
[string] $strLogFilePath = "C:\Temp"
[string] $strLogFileName = "AnyDeskIDs.txt"
[string] $strAnyDeskId = ""

Write-Output "Generiert am $(Get-Date -Format dd.MM.yyyy) um $(Get-Date -Format hh:mm) Uhr. `r`n" | Out-File -FilePath "$strLogFilePath\$strLogFileName"
Write-Output "$strHeadline" | Out-File -FilePath "$strLogFilePath\$strLogFileName" -Append
Write-Output "-------------------------------------"  | Out-File -FilePath "$strLogFilePath\$strLogFileName" -Append

Get-ChildItem "C:\Users" | Select Name, FullName | foreach {
    if( Test-Path ($_.FullName + "\AppData\Roaming\AnyDesk\system.conf") ) {

        $strAnyDeskId = (Get-Content $($_.FullName + "\AppData\Roaming\AnyDesk\system.conf") | Select -Skip 3 | Select-String -Pattern "ad.anynet.id" -SimpleMatch).ToString().Trim() -replace "ad.anynet.id="
        "{0,-25}  {1,9}" -f $_.Name, $strAnyDeskId  | Out-File -FilePath "$strLogFilePath\$strLogFileName" -Append
    }
}