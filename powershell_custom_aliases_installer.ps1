## powershell_custom_aliases_installer.ps1 ##

Function __install
{
  Write-Host "Beginning Powershell_Custom_Aliases module installation....."
  # make sure we have all of the files we need
  $found_module = Test-Path .\powershell_custom_aliases.psm1
  $found_table_of_contents = Test-Path .\powershell_custom_table_of_contents.txt
  $found_profile = Test-Path $profile
  $found_modules = Test-Path "$($profile)\..\..\Modules"

  $new_lines = @()
  $new_lines += "Import-Module '.\Modules\powershell_custom_aliases.psm1' -Global"
  $new_lines += "_init"

  if ($found_module -AND $found_table_of_contents) {

    # copy the table of contents over
    Write-Host "Moving powershell_custom_table_of_contents.txt....."
    if ($found_profile) {
      Copy-Item -Path .\powershell_custom_table_of_contents.txt -Destination "$($profile)\..\powershell_custom_table_of_contents.txt" -Force
    } else {
      New-Item -Path $profile -ItemType File -Force
      Copy-Item -Path .\powershell_custom_table_of_contents.txt -Destination "$($profile)\..\powershell_custom_table_of_contents.txt" -Force
    }

    # copy the module file to the powershell modules directory
    Write-Host "Moving powershell_custom_aliases.psm1....."
    if ($found_modules) {
      Copy-Item -Path .\powershell_custom_aliases.psm1 -Destination "$($profile)\..\Modules\powershell_custom_aliases.psm1" -Force
    } else {
      New-Item -Path "$($profile)\..\Modules\powershell_custom_aliases.psm1" -ItemType File -Force
      Copy-Item -Path .\powershell_custom_aliases.psm1 -Destination "$($profile)\..\Modules\powershell_custom_aliases.psm1" -Force
    }

    # set the profile with the correct commands to start everything when powershell.exe starts
    Write-Host "Updating your profile with startup commands....."
    Add-Content -Path $profile -Value $new_lines

    Write-Host "Installation Complete!"
    Read-Host "Please press [Enter] to finalize the installation.  Powershell will restart."

    # restart shell
    $current_powershell = Get-Process powershell
    Start-Process powershell
    Stop-Process $current_powershell

  } else {
    Write-Error "Couldn't find all of the necessary files in this directory."
    Write-Host ""
    Write-Host "Make sure that this installer is run from the same directory as the module and table of contents."
  }
}

__install