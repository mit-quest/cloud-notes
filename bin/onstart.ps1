$ScriptPath = Split-Path -parent $PSCommandPath
$UtilsScript = [System.IO.Path]::GetFullPath((Join-Path $ScriptPath ".\win_utils.ps1"))

# Import functions from win_utils.ps1
. $UtilsScript

Write-Host "Restarted!!"
Write-Host -NoNewLine "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
