[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)][string]$azurewkspaceid,
      [Parameter(Mandatory=$True,Position=2)][string]$azurewkspacekey,
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
    End {

    }
}

if(!$logfile) {
    $FormattedDate = Get-Date -Format "yyyy-MM-dd-HHmmss" 
    $logfile =  $env:SystemRoot + '\Temp\mma-add-workspace-' + $FormattedDate  +'.log'
}

if(!(Test-Path $logfile)) {
    Write-Verbose "Creating $logfile."
    $NewLogFile = New-Item $logfile -Force -ItemType File
}

Write-Log "Setting Workspace Id ($($azurewkspaceid)) & key($($azurewkspacekey))" -Level Info -Path $logfile
$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
try {
    $mma.AddCloudWorkspace($azurewkspaceId, $azurewkspacekey)
    Write-Log "Reloading Agent ..." -Level Info -Path $logfile
    $mma.ReloadConfiguration()
    Write-Log "Done" -Level Info -Path $logfile
} catch {
    Write-Log "Failed with exception: $_" -Level Error -Path $logfile
}
