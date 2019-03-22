$ScriptPath = Split-Path -parent $PSCommandPath

$UtilsScript = [System.IO.Path]::GetFullPath((Join-Path "$ScriptPath" ".\bin\win_utils.ps1"))
$RestartScript = [System.IO.Path]::GetFullPath((Join-Path "$ScriptPath" ".\bin\onstart.ps1"))

# Import functions from win_utils.ps1
. $UtilsScript

Write-Host "Installing chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
RefreshEnv.cmd

Write-Host "Installing Docker for Windows"
choco install docker-for-windows -y

Write-Host "Turning on optional features for container execution and WSL"
__QI_ActivateOptionalWindowsSettings

# Get the registry key for RunOnce following the currently executing users
# registry path.
$RunOnce = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
Set-ItemProperty $RunOnce "NextRun" ("C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -executionPolicy Unrestricted -File $RestartScript")
