[CmdletBinding()]
Param(
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
    $logfile =  $env:SystemRoot + '\Temp\reset-ccm-policy-' + $FormattedDate  +'.log'
}

if(!(Test-Path $logfile)) {
    Write-Verbose "Creating $logfile."
    $NewLogFile = New-Item $logfile -Force -ItemType File
}

try {
    Write-Log -Level Info -Path $logfile "Deleting Registry.pol from C:\Windows\System32\GroupPolicy\Machine\"
    Remove-Item -Force -Path 'C:\Windows\System32\GroupPolicy\Machine\Registry.pol'
    Write-Log -Level Info -Path $logfile "Resetting SCCM policy using wmic object"
    [void]([wmiclass] "root\ccm:SMS_Client").ResetPolicy(1)
    Write-Log -Level Info -Path $logfile "Triggering SCCM machine policy retrival using wmic object"
    [void]([wmiclass] "root\ccm:SMS_Client").TriggerSchedule("00000000-0000-0000-0000-000000000021")
    Write-Log -Level Info -Path $logfile "Done"
} catch {
    Write-Log "Failed with exception: $_" -Level Error -Path $logfile
}

