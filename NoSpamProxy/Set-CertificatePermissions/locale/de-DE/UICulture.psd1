ConvertFrom-StringData @"

ScriptTitle = NoSpamProxy - Set permissions for the certificate

LocalGroupAdministratorsName = Administratoren

CheckUserPrivilegeGroupCheckInfo = Pruefe, ob die Gruppe existiert.
CheckUserPrivilegeGroupCheckSuccess = Die angegebene Gruppe wurde gefunden.
CheckUserPrivilegeGroupCheckError = Die angegebene Gruppe wurde nicht gefunden!

CheckUserPrivilegeUserMembershipInfo = Pruefe, ob das Benutzerkonto Mitglied der Gruppe ist.
CheckUserPrivilegeUserMembershipSuccess = Das Benutzerkonto ist Mitglied der Gruppe.
CheckUserPrivilegeUserMembershipError = Das Benutzerkonto ist nicht Mitglied der Gruppe!

CheckUserPrivilegeSuccess = Alle Voraussetzungen sind erfuellt. Es geht weiter.
CheckUserPrivilegeError = Es ist ein Fehler aufgetreten! Das Skript wird beendet.

LocalComputerCertStoreInfo = Pruefe, ob ein SSL-Zertifikat im Zertifikatspeicher vorhanden ist.
LocalComputerCertStoreOk = Es wurden folgende Zertifikat gefunden:
LocalComputerCertStoreError = Keine Zertifikate im Zertifikatsspeicher des Computerkontos!

LocalComputerCertStoreListTitle = Nr Datum & Uhrzeit          Thumbprint                                Anzeigename
LocalComputerCertStoreListDateFormat = dd.MM.yyyy HH:mm:ss
LocalComputerCertStoreListLegend = Legende: Rot = Kein privater Schluessel verfuegbar, Gelb = Selbstsigniertes Zertifikat

QueryCertText1 = Auswahl zwischen
QueryCertText2 = und
QueryCertAbort = Abbruch

NoSpamProxyGwRoleInfoText = Ueberarbeite Berechtigungen des privaten Schluessel fuer die Gateway-Rolle.
NoSpamProxyGwRoleAccountInfoText1 = Berechtigung fuer Konto
NoSpamProxyGwRoleAccountInfoText2 = werden gesetzt.
NoSpamProxyGwRolePermissionOk = Berechtigung erfolgreich hinzugefuegt.
NoSpamProxyGwRolePermissionError = Berechtigung konnte nicht hinzugefuegt werden.
NoSpamProxyGwRoleError = Die Gateway Rolle ist nicht installiert.

NoSpamProxyIntraRoleInfoText = Ueberarbeite Berechtigungen des privaten Schluessel fuer die Intranet-Rolle.
NoSpamProxyIntraRoleAccountInfoText1 = Berechtigung fuer Konto
NoSpamProxyIntraRoleAccountInfoText2 = werden gesetzt.
NoSpamProxyIntraRolePermissionOk = Berechtigung erfolgreich hinzugefuegt.
NoSpamProxyIntraRolePermissionError = Berechtigung konnte nicht hinzugefuegt werden.
NoSpamProxyIntraRoleError = Die Intranet Rolle ist nicht installiert.

NoSpamProxyWebPortalRoleInfoText = Ueberarbeite Berechtigungen des privaten Schluessel fuer die Webportal-Rolle.
NoSpamProxyWebPortalRoleAccountInfoText1 = Berechtigung fuer Konto
NoSpamProxyWebPortalRoleAccountInfoText2 = werden gesetzt.
NoSpamProxyWebPortalRolePermissionOk = Berechtigung erfolgreich hinzugefuegt.
NoSpamProxyWebPortalRolePermissionError = Berechtigung konnte nicht hinzugefuegt werden.
NoSpamProxyWebPortalRoleError = Die Webportal Rolle ist nicht installiert.

LocalComputerCertPrivateKeyInfo = Die Anpassung der Berechtigungen ist abgeschlossen.
ExitScriptMessage = Abbruch. Skript wird beendet.
"@