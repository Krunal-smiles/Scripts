[CmdletBinding()]
param([Parameter(Mandatory=$True,Position=1)][string]$installerpath,
      [Parameter(Mandatory=$True,Position=2)][string]$tempdir,
      [Parameter(Mandatory=$False)][string]$logfile
)

function Write-Log {
  [CmdletBinding()]
  Param
  (
      [Parameter(Mandatory=$true,
                 ValueFromPipelineByPropertyName=$true)]
      [ValidateNotNullOrEmpty()]
      [Alias("LogContent")]
      [string]$Message,

      [Parameter(Mandatory=$false)]
      [Alias('LogPath')]
      [string]$Path,
      
      [Parameter(Mandatory=$false)]
      [ValidateSet("Error","Warn","Info")]
      [string]$Level="Info"
  )

  Begin
  {
      # Set VerbosePreference to Continue so that verbose messages are displayed.
      $VerbosePreference = 'Continue'
  }
  Process
  {
       # Format Date for our Log File
       $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

       # Write message to error, warning, or verbose pipeline and specify $LevelText
       switch ($Level) {
           'Error' {
               Write-Error $Message
               $LevelText = 'ERROR:'
               }
           'Warn' {
               Write-Warning $Message
               $LevelText = 'WARNING:'
               }
           'Info' {
               #Write-Verbose $Message
               $LevelText = 'INFO:'
               }
           }
       
       # Write log entry to $Path
       "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append       
  }
  End {}
}

if(!$logfile) {
    $FormattedDate = Get-Date -Format "yyyy-MM-dd-HHmmss" 
    $logfile =  $env:SystemRoot + '\Temp\upgrade-scom-' + $FormattedDate  +'.log'
}

if(!(Test-Path $logfile)) {
    Write-Verbose "Creating $logfile."
    $logfile = New-Item $logfile -Force -ItemType File
}

try {
    # get computer name
    $computername = $env:COMPUTERNAME
    Write-Log -Level Info -Path $logfile "Executing script on $computername"

    #Define the variable to hold the location of Currently Installed Programs
    $UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    
    #Create an instance of the Registry Object and open the HKLM base key
    $reg=[microsoft.win32.registrykey]::OpenBaseKey('LocalMachine','default')

    #Drill down into the Uninstall key using the OpenSubKey Method
    $regkey=$reg.OpenSubKey($UninstallKey) 
    
    #Retrieve an array of string that contain all the subkey names
    $subkeys=$regkey.GetSubKeyNames()

    #Open each Subkey and use GetValue Method to return the required values for each
    foreach($key in $subkeys){
        $thisKey=$UninstallKey+"\\"+$key
        $thisSubKey=$reg.OpenSubKey($thisKey)
        $dName=$thisSubKey.GetValue("DisplayName")
        if($dName -eq "Microsoft Monitoring Agent") {
            #get mma version
            $mmaversion = $thisSubKey.GetValue("DisplayVersion")
            
            #get mma uninstall key
            $uninstall64=$thisSubKey.GetValue("UninstallString") -replace "msiexec.exe","" -replace "/I","" -replace "/X",""
            $uninstall64=$uninstall64.trim()
            #start-process "msiexec.exe" -arg "/X $uninstall64 /qb" -Wait
        }
    }
    $reg.close()
    $array = @()
    if(!$mmaversion) {
        Write-Log -Level Info -Path $logfile "Not able to find MMA on $computername through registry"
    } else {
        Write-Log -Level Info -Path $logfile "Found MMA version $mmaversion running on $computername"
        $mgs=(New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg').GetManagementGroups()
        if ($mgs) {
            Foreach($mg in $mgs) {
                $obj = New-Object PSObject
                $obj | Add-Member -MemberType NoteProperty -Name "managementGroupName" -Value "$($mg.managementGroupName)"
                $obj | Add-Member -MemberType NoteProperty -Name "ManagementServer" -Value "$($mg.ManagementServer)"
                $obj | Add-Member -MemberType NoteProperty -Name "managementServerPort" -Value "$($mg.managementServerPort)"
                $obj | Add-Member -MemberType NoteProperty -Name "IsManagementGroupFromActiveDirectory" -Value "$($mg.IsManagementGroupFromActiveDirectory)"
                $obj | Add-Member -MemberType NoteProperty -Name "ActionAccount" -Value "$($mg.ActionAccount)"
                $array += $obj
                Write-Log -Level Info -Path $logfile "Management Group Name=$($obj.managementGroupName), Management Server=$($obj.ManagementServer), Port=$($obj.managementServerPort), Is Group from AD=$($obj.IsManagementGroupFromActiveDirectory), Action Account=$($obj.ActionAccount)"
            }
        } else {
            Write-Log -Level Info -Path $logfile "No management group configured on $computername"
        }

        $mmastatus=(Get-Service -Name HealthService).Status
        Write-Log -Level Info -Path $logfile "Checking MMA service status ...$mmastatus"

        if("Running" -eq $mmastatus) {
            Write-Log -Level Info -Path $logfile "Attempting to stop MMA service before uninstall"
            Stop-Service -Name HealthService
            Start-Sleep -s 15
            Write-Log -Level Info -Path $logfile "Checking MMA service status ...$((Get-Service -Name HealthService).Status)"
        }
        
        #uninstall MMA
        #$prs = start-process "msiexec.exe" -arg "/X $uninstall64 /qb" -Wait
        $unprs = Uninstall-Package -ProviderName "msi" -Name "Microsoft Monitoring Agent"
        Write-Log -Level Info -Path $logfile "Uninstalled MMA $($unprs)"
    }
    
    #install new version of MMA
    $prs = Start-Process -FilePath $installerpath -Wait -NoNewWindow -WorkingDirectory $tempdir -ArgumentList '/C:"Setup.exe /qn NOAPM=1 AcceptEndUserLicenseAgreement=1"'
    Write-Log -Level Info -Path $logfile "Installed new version of MMA"

    foreach($mgmtg in $array){
        (New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg').AddManagementGroup($mgmtg.managementGroupName,$mgmtg.ManagementServer,$mgmtg.managementServerPort)
        Write-Log -Level Info -Path $logfile "Management Group $($mgmtg.managementGroupName) added to MMA"
    }

    if ("Running" -eq (Get-Service -Name HealthService).Status) {
        Stop-Service -Name HealthService
        Start-Sleep -s 15       
        Write-Log -Level Info -Path $logfile "MMA Service Stopped."
    }

    Start-Service -Name HealthService
    Write-Log -Level Info -Path $logfile "MMA Service Started."

} catch {
    Write-Log "Failed with exception: $_" -Level Error -Path $logfile
}