$strNewPrintserver = "printserver01.xzy.de"

# Prüft, ob das Skript bei diesem Benutzer bereits gelaufen ist
If (-not (Test-Path "C:\Temp\$env:USERNAME-printers.txt")) {

    Write-Host "Druckermigration wird gestartet..."
 
    # Alle Drucker auslesen, die als Netzwerkdrucker markiert sind
        Get-WMIObject Win32_Printer | where{$_.network -eq "true"} | Select ShareName, Default, Name | ForEach {

		# Ausgabe Freigabename
        $_.ShareName
		
		# Ausgabe Standarddrucker
        $_.Default

        # Drucker löschen
        (New-Object -ComObject WScript.Network).RemovePrinterConnection($_.Name)

        # Neue Drucker anlegen
        $printer = [WMIClass]"\\.\root\cimv2:Win32_Printer"
        $printer.AddPrinterConnection("\\" + $strNewPrintserver + "\" + $_.Sharename)

		# Standarddrucker einrichten
        if($_.Default -eq $true) {

            $printer = Get-WmiObject Win32_Printer | ? { $_.name -like "\\" + $strNewPrintserver +"\" + $_.Sharename }
            $printer.SetDefaultPrinter()
        }
    }

	# Ausgabe
    write-host "Fertig" | Out-File "C:\Temp\$env:USERNAME-printers.txt"
}