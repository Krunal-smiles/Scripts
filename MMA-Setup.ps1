[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)][string]$azurewkspaceid,
      [Parameter(Mandatory=$True,Position=2)][string]$azurewkspacekey
)

Write-Host "Setting Workspace Id ($($azurewkspaceid)) & key($($azurewkspacekey))"
$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
try {
    $mma.AddCloudWorkspace($azurewkspaceId, $azurewkspacekey)
    Write-Host "Reloading Agent ..."
    $mma.ReloadConfiguration()
    Write-Host "Done"
} catch {
    $_
}

