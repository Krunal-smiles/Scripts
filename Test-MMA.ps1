# Change workspace id in if to correct workspace id
$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
$res = ''
$wkspaces = $mma.GetCloudWorkspaces()
foreach ($i in $wkspaces) { $res = $res + $i.workspaceid }
if($res -match '80bf334b-1135-4f2d-93cf-669780b1316b') { $true } else { $false }