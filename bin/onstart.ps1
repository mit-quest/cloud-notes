$ScriptPath = Split-Path -parent $PSCommandPath
$UtilsScript = [System.IO.Path]::GetFullPath((Join-Path $ScriptPath ".\win_utils.ps1"))

# Import functions from win_utils.ps1
. $UtilsScript

Write-Host "Installing Ubuntu WSL Distribution"
__QI_WSLInstall
