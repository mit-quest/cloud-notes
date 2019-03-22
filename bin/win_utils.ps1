# Turns on the required optional features in Windows.
#
function __QI_ActivateOptionalWindowsSettings
{
    Enable-WindowsOptionalFeature -Online -FeatureName Containers
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-Powershell
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Hypervisor
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Services
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-Clients
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
}

# Installs the Ubuntu WSL distribution on windows
function __QI_WSLInstall
{
    Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile ubuntu.appx -UseBasicParsing
    Rename-Item ubuntu.appx ~/ubuntu.zip
    Expand-Archive ~/ubuntu.zip ~/Ubunu
    $userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
    [System.Environment]::SetEnvironmentVariable("PATH", $userenv + "C:\Users\Administrator\Ubuntu", "User")
}
