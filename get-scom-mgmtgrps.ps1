$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
try {
    $mgs = $mma.GetManagementGroups()
    foreach($mg in $mgs)
    {
        $mg
    }
	exit 0
} catch {
	exit 1
}