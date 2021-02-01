try {
    (New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg').GetManagementGroups()
} catch {
	Write-host "Failed with exception: $_"
}