[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)][string]$apihost,
      [Parameter(Mandatory=$True,Position=2)][string]$merchantid,
      [Parameter(Mandatory=$True,Position=3)][string]$keyid,
      [Parameter(Mandatory=$True,Position=4)][string]$sharedsecretkey,
      [Parameter(Mandatory=$True,Position=5)][string]$startdate,
      [Parameter(Mandatory=$True,Position=6)][string]$enddate
       )

       $apihost = "apitest.cybersource.com"
       $merchantid = "testrest"
       $keyid = "08c94330-f618-42a3-b09d-e1e43be5efda"
       $sharedsecretkey = "yBJxy6LjM2TmcPGu+GaJrHtkke25fPpUX+UY6/L/1tE="
       $startdate = "2018-10-20"
       $enddate = "2018-10-30"
       
$conndate = (get-date -Format r).toString()
#date: $($conndate)
$key = [System.Convert]::FromBase64String("$($sharedsecretkey)")
$oldstring = "host: $($apihost)
(request-target): get /sfs/v1/file-details?startDate=$($startdate)&endDate=$($enddate)&organizationId=$($merchantid)
v-c-merchant-id: $($merchantid)"
$oldstring = $oldstring -replace "`r",""
$hstring = [System.Text.Encoding]::UTF8.GetBytes($oldstring)
$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
$hmacsha.key = $key
$bsignature = $hmacsha.ComputeHash($hstring)
$signature = [System.Convert]::ToBase64String($bsignature)

$HSignature = "keyid=`"$($keyid)`", algorithm=`"HmacSHA256`", headers=`"host date (request-target) v-c-merchant-id`", signature=`"$($signature)`""
$Hreqtarget = "get /sfs/v1/file-details?startDate=$($startdate)&endDate=$($enddate)&organizationId=$($merchantid)"
$uri = "https://$($apihost)/sfs/v1/file-details?startDate=$($startdate)&endDate=$($enddate)&organizationId=$($merchantid)"

#$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#$headers.Add("host", $apihost)
#$headers.Add("date", $conndate)
#$headers.Add("(request-target)", $Hreqtarget)
#$headers.Add("v-c-merchant-id", $merchantid)
#$headers.Add("Signature", $HSignature)

#$headers
#$uri
#$result = Invoke-WebRequest -Method Get -Headers $headers -Uri $uri
#$result
#Write-Output "<root><header><key>date:$conndate;Signature:$HSignature"
Write-Output "<root><header><key>date</key><value>$conndate</value></header><header><key>Signature</key><value>$HSignature</value></header></root>"
