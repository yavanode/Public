param(
    [Parameter(Mandatory = $True)] $WinAppId
)

# ID variables
#$WinAppId = "Google.Chrome"

# Split the app id to name folders/files
$WinAppIdSplit = $WinAppId.Split(".")
# Use WinAppIdSplit[0] or [1] depending what part of the AppID you want to use. Ex. Logitech.LogiTune => [1]
$WinAppSplitId = $WinAppIdSplit[0]

# Create new folder and Output subfolder
$WinAppFolder = New-Item -ItemType Directory -Path ".\Apps\Winget-$WinAppSplitId"
New-Item -ItemType "Directory" -Path $WinAppFolder\Output
New-Item -ItemType "Directory" -Path $WinAppFolder\Source

# Copy IntuneWinAppUtil.exe from Template folder to the new folder
$IntuneWin = Get-ChildItem -Path ".\_Winget-Template\IntuneWinAppUtil.exe"
Copy-Item -Path $IntuneWin -Destination $WinAppFolder
$IntuneWinApp = "$WinAppFolder\IntuneWinAppUtil.exe"

# Get script files from template folder, copy to source folder
Copy-Item -Path (Get-ChildItem -Path ".\_Winget-Template\Source\*.ps1") -Destination "$WinAppFolder\Source\"

# Set varialbes for the new script files and rename them
$DetectScript = Get-ChildItem -Path "$WinAppFolder\Source\detect-.ps1"
Rename-Item -Path $DetectScript -NewName "detect-$WinAppSplitId.ps1"
$InstallScript = Get-ChildItem -Path "$WinAppFolder\Source\install-.ps1"
Rename-Item -Path $InstallScript -NewName "install-$WinAppSplitId.ps1"

$InstallScriptName = "install-$WinAppSplitId.ps1"

$Scripts = Get-ChildItem -Path "$WinAppFolder\Source\*.ps1"

# Get intune install cmd text file and replace words with variables
$InstallCmdTxtTemplate = Get-ChildItem -Path ".\_Winget-Template\Intune_Install_Cmds.txt"
Copy-Item -Path $InstallCmdTxtTemplate -Destination $WinAppFolder
$InstallCmdTxt = Get-ChildItem -Path "$WinAppFolder\Intune_Install_Cmds.txt"

((Get-Content -path $InstallCmdTxt -Raw) -replace ('replacefile', $InstallScriptName)) | Set-Content -Path $InstallCmdTxt
((Get-Content -path $InstallCmdTxt -Raw) -replace ('replaceappid', $WinAppId)) | Set-Content -Path $InstallCmdTxt


foreach ($Script in $Scripts) {
    ((Get-Content -path $Script -Raw) -replace ('replaceme', $WinAppId)) | Set-Content -Path $Script
}

Write-Host "Folders and files have been created" -ForegroundColor Green
# try catch

$Arguments = "-c $WinAppFolder\Source -s $InstallScriptName -o $WinAppFolder\Output -q n"

Start-Process $IntuneWinApp -ArgumentList $Arguments -Wait
Write-Host "IntuneWin file has been created" -ForegroundColor Green