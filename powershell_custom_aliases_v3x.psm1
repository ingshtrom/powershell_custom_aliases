## powershell_custom_aliases_v3x.psm1 ##
<#

  TODO: rewrite some of the cmdlet-bindings so that they are up to Powershell Cmdlet standards.
    - verbose, error-reporting, etc. options supported
  TODO: support global parameter aliases
  TODO: optimize the searhing in Set-CustomAlias (maybe some sort of background processing as results come in and are displayed right away)


  if you are lost, search for "LAST_WORK"
#>

function PCA-ShowCustomHelp
{
  <#
    .PURPOSE
      * Shows the table of contents (or just certain sections) for the PowershellCustomAliases module
    .PARAMETERS
      * [string] -type
        - [default] "all": shows the whole table of contents help
        - "default": shows the default functions/cmdlets that are available
        - "params": shows all custom global parameters currently available
        - "aliases": shows all custom aliases currently available
    .RETURN
      * [void]
    .NOTES
  #>
  [cmdletbinding()]
  param (
    [string]$type = "all"
  )
  PROCESS {
    Write-Host ""
    Write-Host ":BEGIN"
    Write-Host ""

    __displayCustomHelp $type

    Write-Host ""
    Write-Host ":END"
    Write-Host ""
  }
}

function PCA-SetCustomAlias
{
  <#
    .PURPOSE
      * To create a new alias that serves as a "short-cut" to something else
    .PARAMETERS
      * (string) -type:
        - 0: create an alias and export to preserve this option for future sessions (command_name parameter needs to be defined as well)
        - 1: create a "short-cut" to a certain file (usually a .bat or .exe) (filter and search_start parameters need to be defined as well)
        TODO: - 2: create a "macro" to a cmdlet that includes specific parameters to the cmdlet
      * (string) -alias_name: the new alias that links to the cmdlet or file
      * (string) -command_name: the cmdlet that the alias points to
      * (string) -filter: when searching (type:1 only), the keyword to search on.  Wildcards are defined as '*'
      * (string) -search_start: the directory path to start the search at
      TODO: allow specifying directory paths as well as drive letters for the beginning of the search
    .RETURN
      * [void]
    .NOTES
      * when tested on my machine with Powershellv3, Windows 8 (you can see the rest at my site http://ingshtrom.tumblr.com/pc-spec),
          the speed of the file search was ~17seconds to 400GB of data on a single disk
      * I strongly suggest NOT searching for your file on network drives, this can take longer than trying to get help from Microsoft Custom Service center :P
  #>
  [cmdletbinding()]
  param (
    [string] $type = $(Read-Host "Please enter the type of alias you want to create (0: Using an already defined cmdlet. 1: Search for a specific file path.")
    [string] $alias_name = $(Read-Host "What will be the alias name?"),
    [string] $command_name,
    [string] $filter,
    [string] $search_start
  )
  process {
    # answer the customer's every need until the CPU melts or they say stop
    $is_finished = $false
    do {
      if (([int]$type) -eq 0) {
        $command_name = $(Read-Host "What is the currently defined command?")
        Set-Alias $alias_name $command_name
        Write-Host "Success!"
        Write-Host "You can now use '$($alias_name)' in place of '$($command_name)' while running PowerShell"
        Write-Host "May the force be with you..."
        Export-Alias -Path $custom_aliases_path
        Add-CustomAliasInfo -alias_name $alias_name -command_name $command_name -section "aliases"
      } else if (([int]$type) -eq 1) {
        $filter = $(Read-Host "What keyword should we use to filter the search? (you can use * as wildcard)")
        $search_start = $(Read-Host "Enter a place to start the search at (press [Enter] to search 'C:\'.")
        # getting the drives to search on
        $search_starting_points = @()
        $search_starting_points += "C:\"
        if ($drive_letter -ne "") {
          $drives = @("$search_start")
        }

        $search_path = $null

        # searching the drives recursively
        Write-Host "Searching $($search_starting_points) for '$filter'..........."
        $possible_matches = @()
        foreach ($search_path in $search_starting_points) {
          Write-Host "Searching in $($search_path): ......"
          $start = Get-Date -Verbose
          $result = Get-ChildItem -Path "$($search_path)" -Filter $filter -Recurse -ErrorAction SilentlyContinue
          $end = Get-Date -Verbose
          Write-Host "Search in '$($search_path)' took this long: $($end - $start)"
          if ($result -ne $null) {
            foreach ($match in $result) {
              $possible_matches += $match.FullName
            }
          }
        }

        # output results and set-alias if user found their file
        Write-Host "Found $($possible_matches.count) possible matches."
        $answer = "0"
        if ($possible_matches.count -ne 0) {
          $counter = 1
          Write-Host "0 : NONE of the below options are correct!"
          foreach ($match in $possible_matches) {
            Write-Host "$counter : $match"
            $counter++
          }

          $answer = Read-Host "Enter the number of the path that you want your alias to point to"
        }

        $answer_number = [int]$answer

        # output final results
        if($answer_number -eq 0) {
          Write-Host "I'm sorry this didn't work. Maybe the file you are looking for...doesn't exist."
        } else {
          $alias_path = $possible_matches[$answer_number-1]
          Set-Alias $alias_name $alias_path
          Write-Host "Success!"
          Write-Host "You can now use '$($alias_name)' in place of '$($alias_path)' while running PowerShell"
          Write-Host "May the force be with you..."
          Export-Alias $custom_aliases_path
          Add-CustomAliasInfo -alias_name $alias_name -command_name $alias_path -section "aliases"
        }
      }

      if ($is_finished -eq $false) {
        $title = "Try Again"
        $message = "Do you want to try again/create another alias?"

        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
            "let's do it again!."

        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
            "Stop the torture now!."

        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

        $result = $host.ui.PromptForChoice($title, $message, $options, 0)

        switch ($result) {
          0 {
            $is_finished = $false
            $type = $(Read-Host "Please enter the type of alias you want to create (0: Using an already defined cmdlet. 1: Search for a specific file path.")
            $alias_name = $(Read-Host "What will be the alias name?")
          }
          1 {
            $is_finished = $true
          }
        }
      }
    } while ($is_finished -eq $false)
    PCA-RestartShell
  }
}

function PCA-RestartShell
{
  <#
    .PURPOSE
      * restarts the current powershell session
    .PARAMETERS
      * none
    .EXAMPLE
      * PCA-RestartShell
    .NOTES
      * this is useful for reloading the custom alias file
      * flags supported: -verbose, -debug
  #>
  [cmdletbinding()]
  param ()
  process {
    PCA-RestartProcess -process "powershell"
  }
}

function PCA-RestartProcess
{
  <#
    .PARAMETERS
      * [Mandatory] [string] -process: the name of the process to restart
  #>
  [cmdletbinding()]
  param (
    [parameter(Mandatory=$true)] [string] $process
  )
  process {
    WriteVerbose "Searching for the $($process) process..."
    $current_process = Get-Process -Name
    WriteVerbose "Found the $($process) process!"
    WriteDebug "process id: $($current_process) ."
    WriteVerbose "Starting a new $($process) process..."
    Start-Process $process
    WriteVerbose "Started the process"
    Stop-Process $current_powershell
  }
}

function PCA-AddCustomAliasInfo
{
  <#
    .PURPOSE
      * Adds a new line to the given Table of Contents section (TODO)
    .PARAMETERS
      * [Mandatory] [string] -alias_name: the name of the alias for this entry
      * [Mandatory] [string] -command_name: the name of the command or file that the alias is pointing to
      * [string] -section
        - [default] "aliases": the custom aliases section
        - "params": the global parameters section
        - "default": the default function section (not recommended)
  #>
  [cmdletbinding()]
  param(
    [parameter(Mandatory=$true)] [string] $alias_name = $(Read-Host "What will be the alias name for the entry?"),
    [parameter(Mandatory=$true)] [string] $command_name = $(Read-Host "What is the command name for the entry?"),
    [string] $section = $(Read-Host "What section should this be added to ('aliases', 'params', 'default')?")
  )
  begin {
    WriteVerbose "Finding the file for the section specified";
  }
  process {
    WriteVerbose "Creating the line to add to the Table of Contents"
    $new_line = "  * $($alias_name) : $($command_name)"

    if (202 -eq $(Search-CustomAliasInfo -key $alias_name -file_path $custom_help_path -action "replace" -new_line $new_line)) {
      # do nothing since it was found and replaced
    } else {
      if (Test-Path $custom_help_path) {
        Add-Content -Path $custom_help_path -Value $new_line
      }
    }
    WriteVerbose "Alias written to the Table of contents"
  }
}

function PCA-RemoveCustomAliasInfo
{
  <#
    .PARAMETERS
      * [Mandatory] [string] -alias_name: the name (aka key) of the alias to remove
      * [string] -section:
        - [default] "all": search through all of the sections
        - "default": search the default Table of Contents
        - "aliases": search the aliases Table of Contents
        - "params": search the params Table of Contents
    .RETURN
      * [boolean]:
        - $true: found the line with the given alias_name and removed it
        - $false: couldn't find the line with the given alias_name
    .NOTES
      * none
  #>
  [cmdletbinding()]
  [outputtype([bool])]
  param(
    [parameter(Mandatory=$true)] [string] $alias_name,
    [string] $section = "all"
  )
  PROCESS {
    $return_code = $false
    if (202 -eq $(PCA-SearchCustomAliasInfo -key $alias_name -section $section -action "remove")) {
      $return_code = $true
    }
    return $return_code
  }
}

function PCA-SearchCustomAliasInfo
{
  <#
    .PURPOSE
      * to search for and possibly edit a line in the table of contents
    .PARAMETERS
      * [Mandatory] [string] -key: the alias_name or key of the line that is being searched for
      * [string] -section:
        - [default] "all": search through all of the sections
        - "default": search the default Table of Contents
        - "aliases": search the aliases Table of Contents
        - "params": search the params Table of Contents
      * [string] -action:
        - [default] nothing: just searches for the alias information
        - "remove": searches and removes the alias information
        - "replace": searches and replaces the alias information
      * [string] -new_alias: if replacing, the new alias to replace it with
      * [string] -new_command: if replacing, the new command/file_path to replace it with
    .RETURN
      * [int]:
        - 200: found the line and did nothing
        - 201: found the line and removed it
        - 202: found the line and replaced it with the provided parameters
        - 400: found the line but couldn't find the parameters for replacing it with
        - 404: didn't find the line
  #>
  [cmdletbinding()]
  [outputtype([int])]
  param(
    [parameter(Mandatory=$true)] [string] $key,
    [string] $section,
    [string] $action,
    [string] $new_alias = $null,
    [string] $new_command = $null
  )
  PROCESS {
    $return_code = 404
    $file_path = __tocMap -section $section

    if (Test-Path $file_path) {
      $current_content = Get-Content $file_path
      $new_content = @()
      foreach ($line in $current_content) {
        if ($($line.StartsWith("  * $($key) :"))) {
          if ($action -eq "remove") {   # remove the line
            $return_code = 201
          } elseif ($action -eq "replace") {    # replace the line
            if ($new_alias -eq $null -or $new_command -eq $null) {
              $return_code = 402
              $new_content += $line
            } else {
              $new_content += $new_line
              $return_code = 202
            }
          } else {
            $new_content = "  * $($new_alias) : $($new_command)"
            $return_code = 200
          }
        } else {
          $new_content+= $line
        }
      }
      Set-Content -Path $file_path -Value $new_content -force
    }
    return $return_code
  }
}

# private function used only in Show-CustomHelp
function __displayCustomHelp
{
  [cmdletbinding()]
  param (
    [string] $type = "all"
  )

  # figure out which sections should be displayed
  $file_paths = @()
  if ($type -eq "default") {
    $file_paths += $toc_default;
  } elseif ($type -eq "aliases") {
    $file_paths += $toc_aliases;
  } elseif ($type -eq "params") {
    $file_paths += $toc_params;
  } else {
    $file_paths += $toc_default;
    $file_paths += $toc_aliases;
    $file_paths += $toc_params;
  }

  # display the sections in $file_paths
  foreach ($file_path in $file_paths) {
    $file = Get-Content $file_path
    foreach ($line in $file) {
      Write-Host $line
    }
  }
}

#private function used only in PCA-SearchCustomAliasInfo
function __tocMap
{
  [cmdletbinding()]
  [outputtype([string[]])]
  params {
    [parameter(Mandatory=$true)] [string] $section
  }
  process {
    $return_value = @()
    switch($section) {
      "default" {
        $return_value += $toc_default
        break
      }
      "aliases" {
        $return_value += $toc_aliases
        break
      }
      "params" {
        $return_value += $toc_params
        break
      }
      default {
        $return_value += $toc_default
        $return_value += $toc_params
        $return_value += $toc_aliases
        break
      }
    }
    return $return_value
  }
}

function __displayYesNoQuestion
{
  [cmdletbinding()]
  [outputtype(([int]))]
  param (
    [parameter(Mandatory=$true)]
    [string]$title,

    [parameter(Mandatory=$true)]
    [string]$question,

    [parameter(Mandatory=$true)]
    [string]$answer_yes,

    [parameter(Mandatory=$true)]
    [string]$answer_no,
  )
  process {
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $answer_yes
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", $answer_no
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.ui.PromptForChoice($title, $question, $options, 0)
    return $result
  }
}

$custom_aliases_path = "$($profile)\..\Modules\custom_aliases.txt"
$custom_params_path = "$($profile)\..\Modules\custom_params.txt"
$custom_macros_path = "$($profile)\..\Modules\custom_macros.txt"
$toc_default = "$($profile)\..\toc_default.txt"
$toc_aliases = "$($profile)\..\toc_aliases.txt"
$toc_params = "$($profile)\..\toc_params.txt"

# don't export everything!
# everything with a double underscore will be "private" to the module
Export-ModuleMember -function @("PCA-ShowCustomHelp", "PCA-SetCustomAlias", "PCA-RestartShell", "PCA-RestartProcess", "PCA-AddCustomAliasInfo", "PCA-RemoveCustomAliasInfo")
Export-ModuleMember -variable @("custom_aliases_path", "custom_params_path", "custom_macros_path", "toc_default", "toc_aliases", "toc_params")

if (Test-Path $custom_aliases_path) {
  Import-Alias $custom_aliases_path -Scope Global -ErrorAction Ignore
}

Show-CustomHelp
