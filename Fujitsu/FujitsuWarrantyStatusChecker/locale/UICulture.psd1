ConvertFrom-StringData @"

ScriptTitle = Check Fujitsu warranty / service status

CheckParmSerial = Check whether serial number(s) have been passed as parameters.
CheckParmSerialErrorText = No serial numbers found.
QuerySerialInfoText = Please enter serial number(s) (e.g. YLPW019174;DSET073915)
CheckParmSerialResult = At least one serial number found.

CsvFileTitles = "Serial number";"Product";"AdlerProduct";"AdlerProductFamily";"Support Code";"Support start";"Support end";"Product support end";"Support details";"Warranty group";"Support offering group";"Order number"
CsvFileCreateInfo = Write the data to the CSV file

CheckSerialInfoText = Check the pattern/length of the serial number
CheckSerialInfoOk = Valid serial number detected.
CheckSerialInfoError = The serial number is invalid!

WebsiteFtsQueryTokenInfo = Read the current token of the website.
WebsiteFtsQueryDataInfo = Querying the device data at Fujitsu.
WebsiteFtsDataFilterInfo = Filter and save received data.

DeviceDataSerial = Serial number
DeviceDataProduct = Product
DeviceDataAdlerProduct = AdlerProduct
DeviceDataAdlerProductFamily = AdlerProductFamily
DeviceDataSupportCode = Support Code
DeviceDataSupportStartDate = Support start
DeviceDataSupportEndDate = Support end
DeviceDataSupportStatus = Support status
DeviceDataSupportStatusTextOk = The product is under service.
DeviceDataSupportStatusTextEnd = The product no longer has a service.
DeviceDataProductSupportEndDate = Product support end
DeviceDataProductSupportDetails = Support details
DeviceDataProductWarrentyGroup = Warranty group
DeviceDataProductSupportOfferingGroup = Support offering group
DeviceDataProductOrderNumber = Order number


"@