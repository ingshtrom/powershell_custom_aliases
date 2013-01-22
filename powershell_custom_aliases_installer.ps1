## powershell_custom_aliases_installer.ps1 ##

$custom_aliases_path = "$($profile)\..\Modules\custom_aliases.txt"
$custom_variables_path = "$($profile)\..\Modules\custom_variables.txt"
$custom_macros_path = "$($profile)\..\Modules\custom_macros.txt"
$toc_default = "$($profile)\..\toc_default.txt"
$toc_aliases = "$($profile)\..\toc_aliases.txt"
$toc_macros = "$($profile)\..\toc_variables.txt"
$toc_variables = "$($profile)\..\toc_variables.txt"

Function __install
{
  # # make sure we have all of the files we need
  # $found_module_v3 = Test-Path .\powershell_custom_aliases_v3x.psm1
  # $found_module_v2 = Test-Path .\powershell_custom_aliases_v2x.psm1
  # $found_table_of_contents = Test-Path .\powershell_custom_table_of_contents.txt
  # $found_profile = Test-Path $profile
  # $found_modules = Test-Path "$($profile)\..\..\Modules"
  # $_psVersion = $PSVersionTable.PSVersion.Major

  # $new_lines = @()
  # $new_lines += "Import-Module `"$($profile)\..\Modules\powershell_custom_aliases.psm1`" -Global"
  # $new_lines += "_init"

  # if ($found_module_v2 -AND $found_module_v3 -AND $found_table_of_contents) {

    # copy the table of contents over
    Write-Host "Moving powershell_custom_table_of_contents.txt....."
    if ($found_profile) {
      Copy-Item -Path .\powershell_custom_table_of_contents.txt -Destination "$($profile)\..\powershell_custom_table_of_contents.txt" -Force
    } else {
      New-Item -Path $profile -ItemType File -Force
      Copy-Item -Path .\powershell_custom_table_of_contents.txt -Destination "$($profile)\..\powershell_custom_table_of_contents.txt" -Force
    }

    # copy the module file to the powershell modules directory
    $module_file_name = "powershell_custom_aliases_v3x.psm1"
    if ($_psVersion -eq 2) {
      $module_file_name = "powershell_custom_aliases_v2x.psm1"
    }
    Write-Host "Moving $($module_file_name)....."
    if ($found_modules) {
      Copy-Item -Path ".\$($module_file_name)" -Destination "$($profile)\..\Modules\powershell_custom_aliases.psm1" -Force
    } else {
      New-Item -Path "$($profile)\..\Modules\powershell_custom_aliases.psm1" -ItemType File -Force
    }

    # set the profile with the correct commands to start everything when powershell.exe starts
    Write-Host "Updating your profile with startup commands....."
    Add-Content -Path $profile -Value $new_lines

    Write-Host "Installation Complete!"
    Read-Host "Please press [Enter] to finalize the installation.  Powershell will restart."

    # restart shell
    $current_powershell = Get-Process powershell
    Start-Process powershell
    if ($_psVersion -eq 2) {
      Stop-Process $current_powershell.Id
    } else {
      Stop-Process $current_powershell
    }

  # } else {
  #   Write-Error "Couldn't find all of the necessary files in this directory."
  #   Write-Host ""
  #   Write-Host "Make sure that this installer is run from the same directory as the module and table of contents."
  # }
}

Function _better-install
{
  [cmdletbinding()]
  param()
  process {
    Import-Module ".\powershell_custom_aliases.psm1" -Global

    Write-Verbose "Creating lines to insert into $($profile)"
    $new_lines = @()
    $new_lines += "Import-Module `"$($profile)\..\Modules\powershell_custom_aliases.psm1`" -Global"
    $new_lines += "_init"

    Write-Verbose "Creating objects for file creation."
    $toc_default_object = [psobject] @{
      file_path = "$($profile)\..\toc_default.txt";
      file_contents = @(
        "===================================";
        "DEFAULT:";
        "===================================";
        "  * PCA-SetCustomAlias : same as Set-Alias, but includes session-to-session persistance";
        "  * PCA-RestartShell : terminates this powershell instance and creates a new one";
        "  * PCA-ShowCustomHelp : displays this help screen";
        "  * PCA-RestartProcess : restarts the given process";
        "  * PCA-AddCustomAliasInfo : adds a line to the Table of Contents";
        "  * PCA-RemoveCustomAliasInfo : removes a line from the Table of Contents";
        "";
      )
    };
    $toc_aliases_object = [psobject] @{
      file_path = "$($profile)\..\toc_aliases.txt";
      file_contents = @(
        "===================================";
        "ALIASES:";
        "===================================";
        "";
      )
    }
    $toc_macros_object = [psobject] @{
      file_path = "$($profile)\..\toc_macros.txt";
      file_contents = @(
        "===================================";
        "MACROS:";
        "===================================";
        "";
      )
    }
    $toc_variables_object = [psobject] @{
      file_path = "$($profile)\..\toc_variables.txt";
      file_contents = @(
        "===================================";
        "VARIABLES:";
        "===================================";
        "  * `$custom_aliases_path : $($custom_aliases_path)";
        "  * `$custom_params_path : $($custom_params_path)";
        "  * `$custom_macros_path : $($custom_macros_path)";
        "  * `$toc_default : $($toc_default)";
        "  * `$toc_aliases : $($toc_aliases)";
        "  * `$toc_variables : $($toc_variables)";
        "";
      );
    }
    Write-Verbose "Creating files."
    _create_file $toc_default_object
    _create_file $toc_aliases_object
    _create_file $toc_macros_object
    _create_file $toc_variables_object
    Write-Verbose "Moving module file over"
    Write-Verbose "Restarting Powershell."
    PCA-RestartShell
  }
}

function _create_file
{
  [cmdletbinding()]
  param(
    [parameter(Mandatory=$true] [psobject] $object
  )
  process {
    New-Item -path $object.file_path -itemtype file -force;
    Set-Content $object.file_path $object.file_contents;
  }
}

__install