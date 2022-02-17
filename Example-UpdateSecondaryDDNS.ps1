import-module NSOne.PSHelper.psm1
Connect-NSOne -apitoken <your-ns1-apikey>
$zone = Get-NSOneZone -zone <zone>
$newIP = Get-NSOneDynamicIP -uri <checkip-url>
$zone.primary.secondaries[0].ip = $newIP
$zone | Update-NSOneZone