#----------------------------------------------------------[Declarations]----------------------------------------------------------
### function SendMail
[string] $strEmailServerHostname = "smtp.wydler.eu"
[int] $intEmailServerPort = 25
[string] $strEMailAbsender = "noreply@blog.wydler.eu"
[string] $strEMailSubject = "[TEST] E-Mailversand"
$strEmailBody = @"
Sehr geehrte Damen und Herren,
hier könnte ihr Text stehen.

***Dies ist eine automatisch generierte E-Mail von einer System-E-Mail-Adresse. Bitte antworten Sie nicht auf diese E-Mail.***

"@
[string] $strEmailEmpfaenger = ""

#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function SendMail {
    param (
        [Parameter(Mandatory=$True,Position=1)]
        [string] $MailServerName,

        [Parameter(Mandatory=$False,Position=2)]
        [int] $MailServerPort = 25,

        [Parameter(Mandatory=$True,Position=3)]
        [string] $EmailAbsender,

        [Parameter(Mandatory=$True,Position=4)]
        [string] $EmailEmpfaenger,

        [Parameter(Mandatory=$True,Position=5)]
        [string] $EmailSubject,

        [Parameter(Mandatory=$True,Position=6)]
        [string] $EmailBody,

        [Parameter(Mandatory=$False)]
        [bool] $Tls = $false,

        [Parameter(Mandatory=$False)]
        [string] $MailServerAuthUser,

        [Parameter(Mandatory=$False)]
        [string] $EmailAttachment
    )


    # Neues Objekt
    $oSmtpClient = New-Object System.Net.Mail.SmtpClient($MailServerName, $MailServerPort)
    $oSmtpMessage = New-Object System.Net.Mail.MailMessage($EmailAbsender, $EmailEmpfaenger, $EmailSubject, $EmailBody)

    # (De)aktivert TLS
    $oSmtpClient.EnableSSL = $Tls

    # Prüft ob ein Benutzer angegeben wurde
    if($MailServerAuthUser) {
        
        # Prüft ob die Datei vorhanden ist
        if(Test-Path .\framework.PSCredential.ps1) {
            . .\framework.PSCredential.ps1
            Write-Host "Die Funktion framework.PSCredential.ps1 wurde eingebunden." -ForegroundColor Green


        #Prüft ob für den angegeben Credentials vorhanden sind und fragt ggf. nach dem Passwort
        $oSmtpClient.Credentials = Get-PSCredential "$MailServerAuthUser"

        }
        else {
            return Write-host "Die Datei framework.PSCredential.ps1 ist nicht vorhanden!" -ForegroundColor Red
        }
    }

    # Attach Attachments
    if ($EmailAttachment) {
        $oSmtpMessageAttachment = New-Object System.Net.Mail.Attachment("$EmailAttachment")
        $oSmtpMessage.Attachments.Add($oSmtpMessageAttachment)
    }
    # E-Mail verschicken
    try {
        Write-Host "`nE-Mail wird versendet..."
        $oSmtpClient.Send($oSmtpMessage)
        return Write-Host "E-Mail wurde verschickt." -ForegroundColor Green
    }
    catch [exception] {
        Write-Host $("Fehler: " + $_.Exception.GetType().FullName) -ForegroundColor Red
        Write-Host $("Fehler: " + $_.Exception.Message + "`n") -ForegroundColor Red
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

SendMail -MailServerName $strEmailServerHostname -MailServerPort $intEmailServerPort -EmailAbsender $strEMailAbsender `
-EmailEmpfaenger $strEmailEmpfaenger -EmailSubject $strEMailSubject -EmailBody "$strEmailBody"

SendMail -MailServerName $strEmailServerHostname -MailServerPort $intEmailServerPort -EmailAbsender $strEMailAbsender `
-EmailEmpfaenger $strEmailEmpfaenger -EmailSubject $strEMailSubject -EmailBody "$strEmailBody" -EmailAttachments $strPathToPdfFile