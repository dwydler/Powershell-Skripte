$old_printserver = "ps01"
$new_printserver = "ps02"

# Alle Drucker auslesen, die als Netzwerkdrucker markiert sind und in ein Array speichern.
$printers = @(Get-WMIObject Win32_Printer | where{$_.network -eq "true"} | Select-Object -expandProperty Name)


# Standarddrucker auslesen und in eine Variable speichern
$default_printer = Get-WMIObject Win32_Printer | where{$_.default -eq "true"} | Select-Object -expandProperty Name


# Alle Drucker löschen, die im Array stehen.
foreach($element in $printers) { (New-Object -ComObject WScript.Network).RemovePrinterConnection("$element") }


# Neue Drucker anlegen, welche im Array stehen.
$printer = [WMIClass]"\\.\root\cimv2:Win32_Printer"
foreach($element in $printers) { $printer.AddPrinterConnection($element.replace("$old_printserver", "$new_printserver")) }


# Standarddrucker wieder definieren
$default_printer = $default_printer.replace("$old_printserver", "$new_printserver")

$printer = Get-WmiObject Win32_Printer | ? { $_.name -like "*$default_printer*"}
$printer.SetDefaultPrinter()