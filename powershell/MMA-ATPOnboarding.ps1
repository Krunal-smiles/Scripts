$workspaceId='230335f0-2392-4823-9e4a-f47b9482e990'
$workspaceKey='udWazjInW1mMK9Qchwj5Xoq0MZXS+cdvL1DNjqkJvsfZlUX1k/Vnzu7X9Ogr35N8A87DGqCQqGN9MzWS8Gta7x=='
$proxy_server='localhost'
$proxy_user=''
$proxy_password=''
$reload = $false

try {
    $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
    $workspace = $mma.GetCloudWorkspace($workspaceId)

    if ($null -eq $workspace) {
        $mma.AddCloudWorkspace($workspaceId,$workspaceKey)
        $reload = $true
    }

    if (($mma.proxyUrl -eq '') -or ($null -eq $mma.proxyUrl) -or ($mma.proxyUrl -ne $proxy_server)) {
        $mma.SetProxyInfo($proxy_server, $proxy_user, $proxy_password)
        $reload = $true
    }

    if($reload) {
        $mma.ReloadConfiguration()
    }
    exit 0
} catch {
    Write-Host "Failed with exception: $_"
    exit 1
}