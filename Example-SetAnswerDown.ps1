import-module NSOne.PSHelper.psm1
Connect-NSOne -apitoken <your-ns1-apikey>
Get-NSOneRecord sfatech.com relay.sfatech.com ALIAS | Set-NSOneRecordAnswerMetaProperty sfatech01.dyndns.org. Up True | Update-NSOneRecord
