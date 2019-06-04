[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)][string]$connprofile,
      [Parameter(Mandatory=$True,Position=2)][string]$newusername,
      [Parameter(Mandatory=$True,Position=3)][string]$newpassword,
                                            [string]$gsserver_ip="127.0.0.1",
                                            [uint32]$gsserver_port=1100,
                                            [string]$gsserver_user="admin",
                                            [string]$gsserver_site="MySite")

$gsserver_pwd = ""
[System.security.SecureString]$gsserver_pwd = Read-Host -Prompt "Enter password" -AsSecureString
$ps_cred = New-Object System.Management.Automation.PSCredential -ArgumentList $gsserver_user,$gsserver_pwd 

$server = New-Object -ComObject SFTPCOMInterface.CIServer
$server.connect($gsserver_ip,$gsserver_port,$gsserver_user,$ps_cred.GetNetworkCredential().Password)
if ($null -eq $server) {
    Write-Host "Failed to connect $($gsserver_ip) server"
    exit
}

$site_list = $server.Sites()
for ($i = 0; $i -lt $site_list.Count(); $i++) {
    $site = $site_list.Item($i)
    if ($site.Name -eq $gsserver_site) {
        break
    }
}

if ($site.Name -ne $gsserver_site) {
    Write-Host "No such site ($($gsserver_site)) on the server"
    $server.close()
    exit
}

#Write-Host "Found site $($site.Name)"
$cpcount = $site.GetConnectionProfilesCount()
#Write-Host "Found $($cpcount) connection profiles"
for ($i = 0; $i -lt $cpcount; $i++) {
    $cpinfo = $site.GetConnectionProfileParams($i)
    #Write-Host "Checking connection profile $($cpinfo.Name)"
    if ($cpinfo.Name -eq $connprofile) {
        $cpinfo.User = $newusername
        $cpinfo.Password = $newpassword
        $site.SetConnectionProfileParams($i,$cpinfo)
        Write-Host "Connection profile ($($cpinfo.Name)) updated"
        break
    }
}

$server.close()

