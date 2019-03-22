function NeedsRestart
{
  foreach($Item in $input)
  {
    if($Item -match 'RestartRequired : True')
    {
        return $true
    }
  }
  return $false
}

# Turns on the required optional features in Windows.
#
function __QI_ActivateOptionalWindowsSettings
{
  if (
    (Enable-WindowsOptionalFeature -Online -FeatureName Containers | NeedsRestart) -or
    (Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All | NeedsRestart) -or
    (Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V | NeedsRestart) -or
    (Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All | NeedsRestart) -or
    (Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-Powershell | NeedsRestart) -or
    (Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Hypervisor | NeedsRestart) -or
    (Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Services | NeedsRestart) -or
    (Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-Clients | NeedsRestart) -or
    (Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux | NeedsRestart)
    ){
      return $false
  }

  return $true
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
