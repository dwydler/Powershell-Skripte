[string] $strUsername = ""
[string] $strSitzungsId = ""

[array] $aIgnorUsername = @("services","console","rdp","administrator")


query session | Select-String "$username\s+(\w+)" | Select-Object -Skip 1 | Foreach {

    $strUsername = $_.Matches[0].Groups[1].Value

    if($aIgnorUsername -notcontains $strUsername) {
        $strSitzungsId = ((quser | ? { $_ -match $strUsername} ) -split ' +')[2]
    
        if($strSitzungsId) {
            Write-host "Benutzer $strUsername wird abgemeldet."
            logoff $strSitzungsId
        }
    }
}