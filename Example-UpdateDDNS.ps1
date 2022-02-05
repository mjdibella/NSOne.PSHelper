import-module NSOne.PSHelper.psm1
Connect-NSOne -apitoken <your-ns1-apikey>
Get-NSOneRecord <zone> <domain> A | Set-NSOneRecordAnswer -index 0 $(Get-NSOneDynamicIP -uri <checkuri>) | Update-NSOneRecord
