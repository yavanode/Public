#Change app to detect [Application ID]
$AppToDetect = "replaceme"


<# FUNCTIONS #>

#Log Function
Function Write-Log { 
    PARAM(
        [String]$Message,
        [String]$Path = "$env:ProgramData\AGDIWO\Logs\Detection\$AppToDetect-detection.Log",
        [int]$severity,
        [string]$component
    )

    $TimeZoneBias = Get-WmiObject -Query "Select Bias from Win32_TimeZone"
    $Date = Get-Date -Format "HH:mm:ss.fff"
    $Date2 = Get-Date -Format "MM-dd-yyyy"
    $type = 1

    "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>" | Out-File -FilePath $Path -Append -NoClobber -Encoding default
}

Write-Log -Message "Running detection script"

Function Get-WingetCmd {

    #Get WinGet Path (if admin context)
    $ResolveWingetPath = Resolve-Path "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" | Sort-Object { [version]($_.Path -replace '^[^\d]+_((\d+\.)*\d+)_.*', '$1') }
    if ($ResolveWingetPath) {
        #If multiple version, pick last one
        $WingetPath = $ResolveWingetPath[-1].Path
    }

    #Get Winget Location in User context
    $WingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($WingetCmd) {
        $Script:Winget = $WingetCmd.Source
    }
    #Get Winget Location in System context
    elseif (Test-Path "$WingetPath\winget.exe") {
        $Script:Winget = "$WingetPath\winget.exe"
    }
    else {
        break
    }
}

<# MAIN #>

#Get WinGet Location Function
Get-WingetCmd

#Get "Winget List AppID"
$InstalledApp = & $winget list --Id $AppToDetect --accept-source-agreements | Out-String

#Return if AppID existe in the list
if ($InstalledApp -match [regex]::Escape($AppToDetect)) {
    Write-Log "App installed!"
    return "Installed!"
    exit 0
}

else {
    Write-Log "App not installed!"
    exit 1
}