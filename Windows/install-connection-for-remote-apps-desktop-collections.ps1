<#
.SYNOPSIS
    Installs a connection in RemoteApp and Desktop Connections.
.DESCRIPTION
    This script uses a RemoteApp and Desktop Connections bootstrap file(a .wcx file) to set up a connection in Windows 7 workstation. No user interaction is required.It sets up a connection only for the current user. Always run the script in the user's session.

The necessary credentials must be available either as domain credentials or as cached credentials on the local machine. (You can use Cmdkey.exe to cache the credentials.)

Error status information is saved in event log: (Applications and Services\Microsoft\Windows\RemoteApp and Desktop Connections).

.Parameter WCXPath
    Specifies the path to the .wcx file
    
.Example
    
PS C:\> Install-RADCConnection.ps1 c:\test1\work_apps.wcx

Installs the connection in RemoteApp and Desktop Connections using information
in the specified .wcx file.
    
#>
Param(
    [parameter(Mandatory=$true,Position=0)]
    [string]
    $WCXPath
)


function CheckForConnection {
    Param ( 
        [parameter(Mandatory=$true,Position=0)] 
        [string] $URL 
    )
 
    [bool] $bFound = $false
    
    Get-ChildItem -Path Registry::HKEY_CURRENT_USER\Software\Microsoft\Workspaces\Feeds\* | Select PsPath | foreach {
        
        if( ( (Get-ItemProperty -Path $_.PsPath | Select -ExpandProperty url) -eq $URL) -and ($bFound -eq $false) ) {
            $bFound = $true
        }
    }
    return $bFound
}


# Process the bootstrap file
[string] $wcxExpanded = [System.Environment]::ExpandEnvironmentVariables($WCXPath)
[object[]] $wcxPathResults = @(Get-Item $wcxExpanded 2> $null)

if ($wcxPathResults.Count -eq 0) {
    Write-Host "The .wcx file could not be found!" -ForegroundColor Red
}
else {
    if ($wcxPathResults.Count -gt 1) {
        Write-Host "Please specify a single .wcx file." -ForegroundColor Red
    }
    else {
        [string] $wcxFile = $wcxPathResults[0].FullName
        [xml] $wcxXml = [string]::Join("", (Get-Content -LiteralPath $wcxFile)) 
        [string] $connectionUrl = $wcxXml.workspace.defaultFeed.url

        if (-not $connectionUrl) {
            Write-Host "The .wcx file is not valid!" -ForegroundColor Red
        }
        else {
            if (CheckForConnection $connectionUrl) {
                Write-Host "The connection in RemoteApp and Desktop Connections already exists." -ForegroundColor Yellow
            }
            else {
                
                #
                Start-Process -FilePath rundll32.exe -ArgumentList 'tsworkspace,WorkspaceSilentSetup',$wcxFile -NoNewWindow -Wait

                # check for the Connection in the registry
                if ((CheckForConnection $connectionUrl)) {
                    Write-Host "Connection setup succeeded. !" -ForegroundColor Green
                }
                else {
                    Write-Host "Connection setup failed. `n
                                Consult the event log for failure information: `n
                                (Applications and Services\Microsoft\Windows\RemoteApp and Desktop Connections)." -ForegroundColor Red
                }
            }
        }
    }
}

pause