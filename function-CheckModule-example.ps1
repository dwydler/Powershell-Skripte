#-----------------------------------------------------------[Functions]------------------------------------------------------------

# -----------------------------------------------------------------------------
# Type: 		    Function
# Name: 		    CheckModule
# Description:	    Checks, if the module exists on the system and loaded
# Parameters:		module name
# Return Values:	
# Requirements:					
# -----------------------------------------------------------------------------
Function CheckModule {
    param (
        [Parameter(Mandatory=$True)]
        [string] $Name
    )

	if(-not (Get-Module -name $name) ) {
		if(Get-Module -ListAvailable | Where-Object { $_.name -eq $name }) {
			Import-Module -Name $name
            write-host "Module $name ist bereits geladen." -ForegroundColor Green
		}
		else { 
            write-host "Module $name nicht gefunden!" -ForegroundColor Red
            pause
            exit
		}
	}
	else {
		write-host "Module $name ist geladen." -ForegroundColor Green
	}
}


#-----------------------------------------------------------[Execution]------------------------------------------------------------

CheckModule -Name "ActiveDirectory"
