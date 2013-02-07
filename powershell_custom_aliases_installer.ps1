## powershell_custom_aliases_installer.ps1 ##

$module_directory = "$($profile)\..\Modules"
$module_destination_path = "$($module_directory)\powershell_custom_aliases.psm1"
$custom_aliases_path = "$($module_directory)\custom_aliases.txt"
$custom_variables_path = "$($module_directory)\custom_variables.txt"
$custom_macros_path = "$($module_directory)\custom_macros.txt"
$toc_default = "$($module_directory)\toc_default.txt"
$toc_aliases = "$($module_directory)\toc_aliases.txt"
$toc_macros = "$($module_directory)\toc_macros.txt"
$toc_variables = "$($module_directory)\toc_variables.txt"

Function _better-install
{
  [cmdletbinding()]
  param()
  process {
    Write-Verbose "Creating lines to insert into $($profile)"
    $new_lines = @()
    $new_lines += "Import-Module $($module_destination_path) -Global -WarningAction SilentlyContinue"
    $new_lines += "PCA-ShowCustomHelp"

    Write-Verbose "Checking for the $($module_directory) directory"
    $found_directory = Test-Path $module_directory
    if ($found_directory -eq $false) {
      Write-Verbose "Couldn't find a modules directory, creating one now"
      New-Item -Path $module_directory -ItemType directory -Force
    }

    Write-Verbose "Checking for a $($profile) file"
    $found_profile = Test-Path $profile
    if ($found_profile -eq $false) {
      Write-Verbose "Couldn't find a PowerShell profile, creating one now"
      New-Item -Path $profile -ItemType file -Force
    }
    Write-Verbose "Adding commands to import this module to the current PowerShell profile"
    __add_module_import_to_profile $new_lines

    Write-Verbose "Creating objects for file creation."
    $toc_default_object = [psobject] @{
      file_path = $toc_default
      file_contents = @(
        "==================================="
        "DEFAULT:"
        "==================================="
        "  * PCA-SetCustomAlias : same as Set-Alias, but includes session-to-session persistance"
        "  * PCA-RestartShell : terminates this powershell instance and creates a new one"
        "  * PCA-ShowCustomHelp : displays this help screen"
        "  * PCA-RestartProcess : restarts the given process"
        "  * PCA-AddCustomAliasInfo : adds a line to the Table of Contents"
        "  * PCA-RemoveCustomAliasInfo : removes a line from the Table of Contents"
      )
    }
    $toc_aliases_object = [psobject] @{
      file_path = $toc_aliases
      file_contents = @(
        "==================================="
        "ALIASES:"
        "==================================="
      )
    }
    $toc_macros_object = [psobject] @{
      file_path = $toc_macros
      file_contents = @(
        "==================================="
        "MACROS:"
        "==================================="
      )
    }
    $toc_variables_object = [psobject] @{
      file_path = $toc_variables
      file_contents = @(
        "==================================="
        "VARIABLES:"
        "==================================="
        "  * `$custom_aliases_path : $($custom_aliases_path)"
        "  * `$custom_variables_path : $($custom_variables_path)"
        "  * `$custom_macros_path : $($custom_macros_path)"
        "  * `$toc_default : $($toc_default)"
        "  * `$toc_aliases : $($toc_aliases)"
        "  * `$toc_variables : $($toc_variables)"
      )
    }
    $custom_aliases_object = @{
      file_path = $custom_aliases_path
      file_contents = @("")
    }
    $custom_variables_object = @{
      file_path = $custom_variables_path
      file_contents = @("")
    }
    $custom_macros_object = @{
      file_path = $custom_macros_path
      file_contents = @("")
    }
    Write-Verbose "Creating files."
    _create_file $toc_default_object
    _create_file $toc_aliases_object
    _create_file $toc_macros_object
    _create_file $toc_variables_object
    _create_file $custom_aliases_object
    _create_file $custom_variables_object
    _create_file $custom_macros_object
    Write-Verbose "Moving module file over"
    Copy-Item -Path ".\powershell_custom_aliases.psm1" -Destination $module_destination_path -Force
    Write-Verbose "Restarting Powershell."
    $current_powershell = Get-Process powershell
    Start-Process powershell
    Stop-Process $current_powershell
  }
}

function _create_file
{
  [cmdletbinding()]
  param(
    [parameter(Mandatory=$true)] [psobject] $object
  )
  process {
    New-Item -path $object.file_path -itemtype file -force
    Set-Content $object.file_path $object.file_contents
  }
}

function __add_module_import_to_profile
{
  [cmdletbinding()]
  param (
    [parameter(Mandatory=$true)] [string[]] $new_lines
  )
  $profile_contents = Get-Content $profile
  $new_profile_contents = @()
  ## we can do this since we know there are only two lines
  $found_match = $false
  Write-Verbose "Searching for old import statements for this module"
  foreach ($line in $profile_contents) {
    foreach ($new_line in $new_lines)
    {
      if ($new_line -eq $line) {
        $found_match = $true
      }
    }
    if ($found_match -eq $false) {
      $new_profile_contents += $line
    }
    $found_match = $false
  }
  Write-Verbose "Appending import statements to the PowerShell profile"
  $new_line = $null
  foreach ($new_line in $new_lines) {
    $new_profile_contents += $new_line
  }
  Set-Content -Path $profile -Value $new_profile_contents -Force
}

_better-install
