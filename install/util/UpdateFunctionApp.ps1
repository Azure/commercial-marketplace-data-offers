param ($ResourceGroupName, $FunctionAppName)
if (!$ResourceGroupName -or !$FunctionAppName)
{
  Write-Host "Please provide resource group name and the function app name parameters to proceed."
  exit
}

$destinationPath = "../publisher-azure/functionapp/functionapp.zip"

if(!(Get-AzContext)) {
  Connect-AzAccount
}

if (Test-Path "$destinationPath") {
  Remove-Item -Path $destinationPath
}

$compress = @{
  Path             = "../../powershell-data-function/*.json", "../../powershell-data-function/*.p*1", "../../powershell-data-function/resource"
  CompressionLevel = "Fastest"
  DestinationPath  = $destinationPath
}
Compress-Archive @compress

$updateApp = $false;
if (!(Get-Module -ListAvailable Az.Websites) -and !([environment]::OSVersion.Platform -eq "Unix")) {
  Write-Host "Powershell module Az.Websites is required to update the function app. Please approve the UAC prompt in the next step."
  Read-Host -Prompt "Press enter to continue"
  $processInfo = Start-Process -FilePath "powershell.exe" -Args "Install-Module Az.Websites -MinimumVersion 1.11.0" -Verb runas -PassThru
  $processInfo.WaitForExit()
  $updateApp = $true
}
elseif (!(Get-Module -ListAvailable Az.Websites) -and ([environment]::OSVersion.Platform -eq "Unix")) {
  Write-Host "Powershell module Az.Websites is required to update the function app."
  $processInfo = Start-Process -FilePath "pwsh" -Args "-Command Install-Module Az.Websites -MinimumVersion 1.11.0" -PassThru
  $processInfo.WaitForExit()
  $updateApp = $true
}
else {
  $updateApp = $true
}

if ($updateApp) {
  Write-Host "Updating function app..."
  if ( [environment]::OSVersion.Platform -eq "Unix") {
    $processInfo = Start-Process -FilePath "pwsh" -Args "-Command Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ArchivePath (Resolve-Path $destinationPath).Path -Force" -PassThru 
    $processInfo.WaitForExit()

  }
  else {
    $processInfo = Start-Process -FilePath "powershell.exe" -Args "Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ArchivePath (Resolve-Path $destinationPath).Path -Force" -PassThru
    $processInfo.WaitForExit()
  }
  Write-Host "Update complete."
}
