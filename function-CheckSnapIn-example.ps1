#-----------------------------------------------------------[Functions]------------------------------------------------------------

# -----------------------------------------------------------------------------
# Type: 		    Function
# Name: 		    CheckSnapIn
# Description:	    Checks, if the Snapin is registered and loaded.
# Parameters:		snapin name
# Return Values:	
# Requirements:					
# -----------------------------------------------------------------------------
function CheckSnapIn {
    param (
        [Parameter(Mandatory=$True)]
        [string] $Name
    )

    if (get-pssnapin $name -ea "silentlycontinue") {
        write-host "PSsnapin $name ist bereits geladen." -ForegroundColor Green
    }
    elseif (get-pssnapin $name -registered -ea "silentlycontinue") {
        Add-PSSnapin $name
        write-host "PSsnapin $name ist geladen." -ForegroundColor Green
    }
    else {
        write-host "PSSnapin $name nicht gefunden!" -ForegroundColor Red
        pause
        exit
    }
}


#-----------------------------------------------------------[Execution]------------------------------------------------------------

CheckSnapIn -Name "Microsoft.Exchange.Management.PowerShell.E2010"
