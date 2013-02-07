## powershell_custom_aliases_v3x.psm1 ##
<#

  [TODO]: rewrite some of the cmdlet-bindings so that they are up to Powershell Cmdlet standards.
    - verbose, error-reporting, etc. options supported
  [TODO]: support global parameter aliases
  [TODO]: optimize the searhing in Set-CustomAlias (maybe some sort of background processing as results come in and are displayed right away)
  [TODO] add Verbose statements
  search for "ASSUME" to find assumptions that need to be removed as assumptions and implemented as code
#>

## DONE
function PCA-ShowCustomHelp
{
  <#
    .SYNOPSIS
      Shows the table of contents (or just certain sections) for the PowershellCustomAliases module
  #>
  [CmdletBinding()]
  PARAM (
    [string]$type = "all"
  )
  BEGIN {
    Write-Verbose "BEGIN : PCA-ShowCustomHelp"
  }
  PROCESS {
    Write-Verbose "Checking the `$type for invalid values"
    if ($type -eq "all" -or $type -eq "default" -or $type -eq "macros" -or $type -eq "aliases" -or $type -eq "variables") {
      Write-Verbose "The value for `$type is valid"
    } else {
      Write-Warning "The value for the `$type parameter must be one of the following values: `$null, 'default', 'variables', 'aliases', 'macros'."
      Write-Host "The function will continue and assume `$type='all'"
      $type = "all"
    }
    Write-Host ""
    Write-Host ":BEGIN"
    Write-Host ""

    __displayCustomHelp $type

    Write-Host ""
    Write-Host ":END"
    Write-Host ""
  }
  END {
    Write-Verbose "END : PCA-ShowCustomHelp"
  }
}

function PCA-CreateAlias
{
  <#
    .SYNOPSIS
      To create a new alias that serves as a "short-cut" to something else
      TODO: allow specifying directory paths as well as drive letters for the beginning of the search
    .PARAMETER type
      The type of alias you are creating.
        (1) alias/cmdlet/function -> alias : pretty simple. ex. mstsc -> rdp would result in the ability to do "rdp /v:machine_name"
        (2) file -> alias : usually .bat|.exe extensions ex. "C:\Users\user_name\Desktop\firefox.exe" -> firefox would let you type "firefox" to run "firefox.exe" from any location
        [TODO] (3) script block -> alias : if you need multiple lines, use ';' (semicolon) at the end of statements.  so { mstsc /v:machine_name; } -> rdp would result in saying "rdp" to run that command with parameters
        [TODO] (4) object/variable -> variable : ex. "C:\Users\user_name\Desktop" -> desktop would result in the ability to say "Set-Location $desktop"
    .PARAMETER alias
      The name of the alias that you are creating (or the variable if type == 4)
    .PARAMETER command
      The name of the command that the $alias will point to  (only used in type 1)
    .PARAMETER filter
      The search filter for when you are looking for a file (only used in type 2)
    .PARAMETER search_start
      [default] = "C:\"
      The directory path from which to start the search. This can range from general--"C:\"--to precise--"C:\Program Files\company\product\" (only used in type 2)
    .PARAMETER script
      The script block that will be run whenever $alias is called from Powershell
    .PARAMETER variable
      The value of the variable that is being pointed to by $alias (only used in type 4)
      This only supports string values at the moment. See the [NOTES] section for contact information to submit feature requests
    .NOTES
      When tested on my machine with Powershellv3, Windows 8, the speed of the file search was ~17seconds to 400GB of data on a single disk
      I strongly suggest NOT searching for your file on network drives, this can take longer than trying to get help from Microsoft Custom Service center :P
      When creating this module, I was aiming for it to be used as a bridge between novices and expert PowerShell users.  As such, there is lack of functionality in places.  If you would like more functionality, contact me on GitHub (ingshtrom) and create an issue in this repo.
      When using this Cmdlet, it is NOT always necessary to use quotation marks around each parameter passed in.  The same rules apply here as they do in the rest of PowerShell
    .LINK
      What my PC setup is: http://ingshtrom.tumblr.com/pc-spec for performance comparison
    .EXAMPLE
      PCA-CreateAlias
      This will walk you through the creation process and make sure you have input all the necessary variables.
    .EXAMPLE
      PCA-CreateAlias -type 1 -alias rdp -command mstsc
      This will create an alias that lets you type "rdp -v machine_name" rather than "mstsc -v machine_name"
    .EXAMPLE
      PCA-CreateAlias -type 2 -alias "st" -filter "sublime_text*" -search_start "C:\"
      This will search recursively, starting at $search_start, using the $filter and then display the results.  You will then need to enter a number matching the correct file to bind the alias to.
      The $filter can use the asterisk "*" as an unlimited wildcard.  The regular expression equivalent is ".*" (dot asterisk)
    .EXAMPLE
      PCA-CreateAlias -type 2 -alias "st" -filter "sublime_text*"
      The same as above, except that the search starts at "C:\" (default).
    .EXAMPLE
      PCA-CreateAlias -type 3 -alias "rdp_machine" -script "{ mstsc /v:machine_name; }"
      This will create a binding where typing "rdp_machine" at the PowerShell prompt will actually run the code entered for the $script parameter.
      Note that the $script variable needs to be entered as a [string], not an actual script block object.
    .EXAMPLE
      PCA-CreateAlias -type 4 -alias "desktop" -variable "C:\Users\user_name\Desktop"
      This creates a global variable that can be used just like any other variable.
      The PowerShell equivalent would be to type this line every time PowerShell started: "GLOBAL:$desktop = `"C:\Users\user_name\Desktop`"".
  #>
  [CmdletBinding()]
  param (
    [string] $type = $(Read-Host "Please enter the type of alias you want to create (run 'Get-Help PCA-CreateAlias' for more information)."),
    [string] $alias = $(Read-Host "What will be the alias name?"),
    [string] $command,
    [string] $filter,
    [string] $search_start,
    [string] $script,
    [string] $variable
  )
  BEGIN {
    Write-Verbose "BEGIN : PCA-CreateAlias"
  }
  process {
    # answer the customer's every need until the CPU melts or they say stop
    $is_finished = $false
    do {
      if (([int]$type) -eq 1) {     # cmdlet/function/alias -> alias
        $command = $(Read-Host "What is the currently defined command?")
        Set-Alias $alias $command
        Write-Host "Success!"
        Write-Host "You can now use '$($alias)' in place of '$($command)' while running PowerShell"
        Write-Host "May the force be with you..."
        Export-Alias -Path $custom_aliases_path
        PCA-AddCustomAliasInfo -alias $alias -command $command -section "aliases"
      } elseif (([int]$type) -eq 2) {   # file -> alias
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
          Set-Alias $alias $alias_path
          Write-Host "Success!"
          Write-Host "You can now use '$($alias)' in place of '$($alias_path)' while running PowerShell"
          Write-Host "May the force be with you..."
          Export-Alias $custom_aliases_path
          PCA-AddCustomAliasInfo -alias $alias -command $alias_path -section "aliases"
        }
      } elseif (([int]$type) -eq 3) {   # script block -> alias
        # [ASSUME] the user ALWAYS has { } around the script block
        # [ASSUME] the user hasn't already defined this alias, but with a different function
        $new_macro = "Function $($alias) $($script)"
        $current_macros = Get-Content $custom_macros_path
        $macro_defined = $false
        foreach ($macro in $current_macros) {
          if ($macro -eq $new_macro) {
            $macro_defined = $true
          }
        }
        if ($macro_defined -eq $false) {
          $current_macros += $new_macro
        }
        Set-Content -Path $custom_macros_path -Value $current_macros -Force
      } elseif (([int]$type) -eq 4) {   # variable -> alias
        # [ASSUME] the user only inputs strings for the value of the variable
        $new_variable = "GLOBAL:`$$($alias) = $($variable)"
        $current_variables = Get-Content $custom_variables_path
        $variable_defined = $false
        foreach ($variable in $current_variables) {
          if ($variable -eq $new_variable) {
            $variable_defined = $true
          }
        }
        if ($variable_defined -eq $false) {
          $current_variables += $new_variable
        }
        Set-Content -Path $custom_variables_path -Value $current_variables -Force
      } else {
        Write-Warning "You entered an invalid `$type option.  Please try again."
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
            $alias = $(Read-Host "What will be the alias name?")
          }
          1 {
            $is_finished = $true
          }
        }
      }
    } while ($is_finished -eq $false)
    PCA-RestartShell
  }
  END {
    Write-Verbose "END : PCA-CreateAlias"
  }
}

function PCA-RestartShell
{
  <#
    .SYNOPSIS
      restarts the current powershell session
    .EXAMPLE
      PCA-RestartShell
    .NOTES
      this is useful for reloading the custom alias file
      flags supported: -verbose, -debug
  #>
  [CmdletBinding()]
  PARAM ()
  BEGIN {
    Write-Verbose "BEGIN : PCA-RestartShell"
  }
  PROCESS {
    PCA-RestartProcess -process "powershell"
  }
  END {
    Write-Verbose "END : PCA-RestartShell"
  }
}

function PCA-RestartProcess
{
  <#
    .PARAMETER process
    the name of the process to restart
  #>
  [CmdletBinding()]
  PARAM (
    [parameter(Mandatory=$true)] [string] $process
  )
  BEGIN {
    Write-Verbose "BEGIN : PCA-RestartProcess"
  }
  PROCESS {
    Write-Verbose "Searching for the $($process) process..."
    $current_process = Get-Process $process
    Write-Verbose "Found the $($process) process!"
    Write-Debug "process id: $($current_process) ."
    Write-Verbose "Starting a new $($process) process..."
    Start-Process $process
    Write-Verbose "Started the new process"
    Write-Host $current_process
    Stop-Process $current_process
    Write-Verbose "Stopped the old process"
  }
  END {
    Write-Verbose "END : PCA-RestartProcess"
  }
}

function PCA-AddCustomAliasInfo
{
  <#
    .SYNOPSIS
      * Adds a new line to the given Table of Contents section (TODO)
    .PARAMETER alias
    the name of the alias for this entry
    .PARAMETER command
    the name of the command or file that the alias is pointing to
    .PARAMETER section
      - [default] "aliases": the custom aliases section
      - "params": the global parameters section
      - "default": the default function section (not recommended)
  #>
  [cmdletbinding()]
  param(
    [parameter(Mandatory=$true)] [string] $alias = $(Read-Host "What will be the alias name for the entry?"),
    [parameter(Mandatory=$true)] [string] $command = $(Read-Host "What is the command name for the entry?"),
    [string] $section = $(Read-Host "What section should this be added to ('aliases', 'params', 'default')?")
  )
  begin {
    Write-Verbose "Finding the file for the section specified"
  }
  process {
    Write-Verbose "Creating the line to add to the Table of Contents"
    $new_line = "  * $($alias) : $($command)"

    if (202 -eq $(PCA-SearchCustomAliasInfo -key $alias -section $section -action "replace" -new_alias $alias -new_command $command)) {
      # do nothing since it was found and replaced
    } else {
      $custom_help_paths = __tocMap $section
      foreach ($help_path in $custom_help_paths) {
        if (Test-Path $help_path) {
          Add-Content -Path $help_path -Value $new_line
          break     #only want to add it to the first one.  no reason to add it to all of them
        }
      }
    }
    Write-Verbose "Alias written to the Table of contents"
  }
}

function PCA-RemoveCustomAliasInfo
{
  <#
    .PARAMETERS
      * [Mandatory] [string] -alias: the name (aka key) of the alias to remove
      * [string] -section:
        - [default] "all": search through all of the sections
        - "default": search the default Table of Contents
        - "aliases": search the aliases Table of Contents
        - "params": search the params Table of Contents
    .RETURN
      * [boolean]:
        - $true: found the line with the given alias and removed it
        - $false: couldn't find the line with the given alias
    .NOTES
      * none
  #>
  [cmdletbinding()]
  [outputtype([bool])]
  param(
    [parameter(Mandatory=$true)] [string] $alias,
    [string] $section = "all"
  )
  PROCESS {
    $return_code = $false
    if (202 -eq $(PCA-SearchCustomAliasInfo -key $alias -section $section -action "remove")) {
      $return_code = $true
    }
    return $return_code
  }
}

function PCA-SearchCustomAliasInfo
{
  <#
    .SYNOPSIS
    to search for and possibly edit a line in the table of contents
    .PARAMETER key
    the alias or key of the line that is being searched for
    .PARAMETER section
      - [default] "all": search through all of the sections
      - "default": search the default Table of Contents
      - "aliases": search the aliases Table of Contents
      - "params": search the params Table of Contents
    .PARAMETER action
      - [default] nothing: just searches for the alias information
      - "remove": searches and removes the alias information
      - "replace": searches and replaces the alias information
    .PARAMETER new_alias
    if replacing, the new alias to replace it with
    .PARAMETER new_command
    if replacing, the new command/file_path to replace it with
    .OUTPUTS
    return code : [int]
      - 200: found the line and did nothing
      - 201: found the line and removed it
      - 202: found the line and replaced it with the provided parameters
      - 400: found the line but couldn't find the parameters for replacing it with
      - 404: didn't find the line
  #>
  [CmdletBinding()]
  [OutputType([int])]
  PARAM (
    [Parameter(Mandatory=$true)] [string] $key,
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
## DONE
Function __displayCustomHelp
{
  [cmdletbinding()]
  param (
    [string] $type = "all"
  )
  begin {
    Write-Verbose "BEGIN : __displayCustomHelp"
  }
  process {
    Write-Verbose "__displayCustomHelp START!"
    Write-Verbose "Figure out which sections should be displayed"
    $file_paths = @()
    if ($type -eq "default" -or $type -eq "all") {
      Write-Verbose "Adding `$toc_default"
      $file_paths += $toc_default
    }
    if ($type -eq "aliases" -or $type -eq "all") {
      Write-Verbose "Adding `$toc_aliases"
      $file_paths += $toc_aliases
    }
    if ($type -eq "variables" -or $type -eq "all") {
      Write-Verbose "Adding `$toc_variables"
      $file_paths += $toc_variables
    }
    if ($type -eq "macros" -or $type -eq "all") {
      Write-Verbose "Adding `$toc_macros"
      $file_paths += $toc_macros
    }

    Write-Verbose "Display the sections that were found from the previous step"
    foreach ($file_path in $file_paths) {
      $file = Get-Content $file_path
      foreach ($line in $file) {
        Write-Host $line
      }
    }
   Write-Verbose "__displayCustomHelp END!"
  }
  end {
    Write-Verbose "END : __displayCustomHelp"
  }
}

#private function used only in PCA-SearchCustomAliasInfo
Function __tocMap
{
  [cmdletbinding()]
  [outputtype([string[]])]
  param (
    [parameter(Mandatory=$true)] [string] $section
  )
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
    [string]$answer_no
  )
  begin {
    Write-Verbose "BEGIN : __displayYesNoQuestion"
  }
  process {
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $answer_yes
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", $answer_no
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.ui.PromptForChoice($title, $question, $options, 0)
    return $result
  }
  end {
    Write-Verbose "END : __displayYesNoQuestion"
  }
}

$custom_aliases_path = "$($profile)\..\Modules\custom_aliases.txt"
$custom_variables_path = "$($profile)\..\Modules\custom_variables.txt"
$custom_macros_path = "$($profile)\..\Modules\custom_macros.txt"
$toc_default = "$($profile)\..\Modules\toc_default.txt"
$toc_aliases = "$($profile)\..\Modules\toc_aliases.txt"
$toc_macros = "$($profile)\..\Modules\toc_macros.txt"
$toc_variables = "$($profile)\..\Modules\toc_variables.txt"

# don't export everything!
# everything with a double underscore will be "private" to the module
Export-ModuleMember -function @("PCA-ShowCustomHelp", "PCA-CreateAlias", "PCA-RestartShell", "PCA-RestartProcess", "PCA-AddCustomAliasInfo", "PCA-RemoveCustomAliasInfo")
Export-ModuleMember -variable @("custom_aliases_path", "custom_variables_path", "custom_macros_path", "toc_default", "toc_aliases", "toc_variables", "toc_macros")

if (Test-Path $custom_aliases_path) {
  Import-Alias $custom_aliases_path -Scope Global -ErrorAction Ignore
}
