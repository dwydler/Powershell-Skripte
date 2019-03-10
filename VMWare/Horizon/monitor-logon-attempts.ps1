Clear-Host

[string] $strMailBetreff = "Info: VMWare Horizon Security Server"

[string] $strMailServerAdresse = "Mailserver"
[int] $intMailServerPort = 587
[bool] $bMailServerSsl = $true
[string] $strMailAbesender = "abc@domain.de"
[string] $strMailAbsenderBenutzer = "benutzer"
[string] $strMailAbsenderPasswort = "passort"

[array] $aMailEmpfaenger = @("empfänger1", "empfänger2")


# Letztes Ereignis auslesen
$Event = Get-EventLog -LogName Security -InstanceId 4625 -Newest 1 -Message "*wsnm.exe*"
$MailBody= @"
Fehler beim Anmelden eines Kontos.

Servername:`t`t$($Event.ReplacementStrings[1])
Domäne:`t`t$($Event.ReplacementStrings[2])
Benutzername:`t$($Event.ReplacementStrings[5])
Zeitstempel:`t`t$($Event.TimeGenerated)
"@


# E-Mail verschicken
$MailMessage = New-Object System.Net.Mail.MailMessage
$MailMessage.From = $strMailAbesender

foreach($a in $aMailEmpfaenger) {
    $MailMessage.To.Add($a)
}

$MailMessage.IsBodyHtml = 0
$MailMessage.Subject = $strMailBetreff
$MailMessage.Body = $MailBody
$MailMessage.Priority = "High"

$SmtpClient = New-Object System.Net.Mail.SmtpClient
$SmtpClient.EnableSsl = $bMailServerSsl
$SmtpClient.Port = $intMailServerPort
$SmtpClient.host = $strMailServerAdresse
$SmtpClient.Credentials = New-Object System.Net.NetworkCredential($strMailAbsenderBenutzer, $strMailAbsenderPasswort); 
$SmtpClient.Send($MailMessage)