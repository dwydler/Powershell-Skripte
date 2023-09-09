ConvertFrom-StringData @"

ScriptTitle = NoSpamProxy - Set permissions for the certificate

LocalGroupAdministratorsName = Administrators

CheckUserPrivilegeGroupCheckInfo = Check if the group exists.
CheckUserPrivilegeGroupCheckSuccess = The specified group was found.
CheckUserPrivilegeGroupCheckError = The specified group was not found!

CheckUserPrivilegeUserMembershipInfo = Check if the user account is a member of the group.
CheckUserPrivilegeUserMembershipSuccess = The user account is members of the group.
CheckUserPrivilegeUserMembershipError = The user account is not a member of the group!

CheckUserPrivilegeSuccess = All requirements are met. It goes on.
CheckUserPrivilegeError = An error has occurred! The script will exit.

LocalComputerCertStoreInfo = Check if an SSL certificate is present in the certificate store.
LocalComputerCertStoreOk = The following certificates were found:
LocalComputerCertStoreError = No certificates in computer account certificate store!

LocalComputerCertStoreListTitle = Nr Date & Time              Thumbprint                                Displayname
LocalComputerCertStoreListDateFormat = dd.MM.yyyy HH:mm:ss
LocalComputerCertStoreListLegend = Legend: Red = No private key available, Yellow = Self-signed certificate

QueryCertText1 = Choice between
QueryCertText2 = and
QueryCertAbort = Abort

NoSpamProxyGwRoleInfoText = Revise private key permissions for the gateway role.
NoSpamProxyGwRoleAccountInfoText1 = Permission for account
NoSpamProxyGwRoleAccountInfoText2 = are set.
NoSpamProxyGwRolePermissionOk = Permission added successfully.
NoSpamProxyGwRolePermissionError = Permission could not be added.
NoSpamProxyGwRoleError = The gateway role is not installed.

NoSpamProxyIntraRoleInfoText = Revise private key permissions for the gateway role.
NoSpamProxyIntraRoleAccountInfoText1 = Permission for account
NoSpamProxyIntraRoleAccountInfoText2 = are set.
NoSpamProxyIntraRolePermissionOk = Permission added successfully.
NoSpamProxyIntraRolePermissionError = Permission could not be added.
NoSpamProxyIntraRoleError = The intranet role is not installed.

NoSpamProxyWebPortalRoleInfoText = Revise private key permissions for the webportal role.
NoSpamProxyWebPortalRoleAccountInfoText1 = Permission for account
NoSpamProxyWebPortalRoleAccountInfoText2 = are set.
NoSpamProxyWebPortalRolePermissionOk = Permission added successfully.
NoSpamProxyWebPortalRolePermissionError = Permission could not be added.
NoSpamProxyWebPortalRoleError = The web portal role is not installed.

LocalComputerCertPrivateKeyInfo = The adjustment of permissions is complete.
ExitScriptMessage = Abort. Script is exiting.
"@