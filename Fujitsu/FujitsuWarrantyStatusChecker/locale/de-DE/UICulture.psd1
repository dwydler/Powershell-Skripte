ConvertFrom-StringData @"

ScriptTitle = Fujitsu Garantie / Service Status ueberpruefen

CheckParmSerial = Überprüfen ob Seriennummern(n) als Parameter übergeben worden sind.
CheckParmSerialErrorText = Keine Seriennummern gefunden.
QuerySerialInfoText = Bitte Seriennummer(n) eingeben (z.B. YLPW019174;DSET073915)
CheckParmSerialResult = Mindestens eine Seriennummer gefunden.

CsvFileTitles = "Seriennummer";"Produkt";"AdlerProdukt";"AdlerProduktFamilie";"Support Code";"Support Start";"Support Ende";"Produkt Support Ende";"Support Details";"Garantie Gruppe";"Support Offering Gruppe";"Bestellnummer"
CsvFileCreateInfo = Schreibe die Daten in die CSV Datei

CheckSerialInfoText = Überprüfen des Muster/Länge der Seriennummer
CheckSerialInfoOk = Gültige Seriennummer erkannt.
CheckSerialInfoError = Die Seriennummer ist ungültig!

WebsiteFtsQueryTokenInfo = Aktuellen Token der Webseite auslesen
WebsiteFtsQueryDataInfo = Abfrage der Daten des Geräts bei Fujitsu.
WebsiteFtsDataFilterInfo = Erhaltene Daten filtern und speichern.

DeviceDataSerial = Seriennummer
DeviceDataProduct = Produkt
DeviceDataAdlerProduct = AdlerProdukt
DeviceDataAdlerProductFamily = AdlerProduktFamilie
DeviceDataSupportCode = Support Code
DeviceDataSupportStartDate = Support Start
DeviceDataSupportEndDate = Support Ende
DeviceDataSupportStatus = Support Status
DeviceDataSupportStatusTextOk = Das Produkt ist unter Service.
DeviceDataSupportStatusTextEnd = Das Produkt hat keinen Service mehr.
DeviceDataProductSupportEndDate = Produkt Support Ende
DeviceDataProductSupportDetails = Support Details
DeviceDataProductWarrentyGroup = Garantie Gruppe
DeviceDataProductSupportOfferingGroup = Support Offering Gruppe
DeviceDataProductOrderNumber = Bestellnummer


"@