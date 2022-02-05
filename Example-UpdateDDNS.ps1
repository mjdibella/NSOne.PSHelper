import-module NSOne.PSHelper.psm1
Connect-NSOne -apitoken <your-ns1-apikey>
$oldIP = Get-NSOneRecord <zone> <domain> A | Get-NSOneRecordAnswer -index 0
$newIP = Get-NSOneDynamicIP -uri <checkuri>
if ($newIP) {
    if ($oldIP -ne $newIP) {
        Get-NSOneRecord <zone> <domain> A | Set-NSOneRecordAnswer -index 0 $newIP | Update-NSOneRecord
    }
}