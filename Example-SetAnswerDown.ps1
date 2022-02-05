import-module NSOne.PSHelper.psm1
Connect-NSOne -apitoken <your-ns1-apikey>
Get-NSOneRecord <zone> <domain> <TYPE> | Set-NSOneRecordAnswerMetaProperty <answer> Up False | Update-NSOneRecord
