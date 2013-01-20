## powershell_custom_aliases_v3x.psm1 ##
<#

  TODO: rewrite some of the cmdlet-bindings so that they are up to Powershell Cmdlet standards.
    - verbose, error-reporting, etc. options supported
  TODO: write a funciton for restarting a given process
  TODO: support global parameter aliases
  TODO: optimize the searhing in Set-CustomAlias (maybe some sort of background processing as results come in and are displayed right away)


  if you are lost, search for "LAST_WORK"
#>

Function Show-CustomHelp
{
  <#
    .PURPOSE
      * Shows the table of contents (or just certain sections) for the PowershellCustomAliases module
    .PARAMETERS
      * (string) -type
        - [default] "all": shows the whole table of contents help
        - "default": shows the default functions/cmdlets that are available
        - "params": shows all custom global parameters currently available
        - "aliases": shows all custom aliases currently available
  #>
  params {
    [string]$type = "all"
  }

  PROCESS {
    Write-Host ""
    Write-Host ":BEGIN"
    Write-Host ""

    __writeCustomHelp($type);

    Write-Host ""
    Write-Host ":END"
    Write-Host ""
  }
}

# private function used only in Show-CustomHelp
Function __writeCustomHelp
{
  params {
    [string]$type = "all"
  }

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

# used for commands that are already in the global space
# type and alias_name are always required
# if type == 0 >> command_name is required
# if type == 1 >> filter and drive_letter is required
Function Set-CustomAlias
{
  <#
    .PURPOSE
      * To create a new alias that serves as a "short-cut" to something else
    .PARAMETERS
      * (string) -type:
        - 0: create an alias and export to preserve this option for future sessions (command_name parameter needs to be defined as well)
        - 1: create a "short-cut" to a certain file (usually a .bat or .exe) (filter and drive_letter parameters need to be defined as well)
        TODO: - 2: create a "macro" to a cmdlet that includes specific parameters to the cmdlet
      * (string) -alias_name: the new alias that links to the cmdlet or file
      * (string) -command_name: the cmdlet that the alias points to
      * (string) -filter: when searching (type:1 only), the keyword to search on.  Wildcards are defined as '*'
      * (string) -drive_letter: the drive to search on (defaults to all "FileSystem" drives, which includes mapped network drives)
      TODO: allow specifying directory paths as well as drive letters for the beginning of the search
    .NOTES
      * when tested on my machine with Powershellv3, Windows 8 (you can see the rest at my site http://ingshtrom.tumblr.com/pc-spec),
          the speed of the file search was ~17seconds to 400GB of data on a single disk
      * I strongly suggest NOT searching for your file on network drives, this can take longer than trying to get help from Microsoft Custom Service center :P
  #>
  param(
    [string]$type = $(Read-Host "Please enter the type of alias you want to create (0: Using an already defined cmdlet. 1: Search for a specific file path.")
    [string]$alias_name = $(Read-Host "What will be the alias name?"),
    [string]$command_name,
    [string]$filter,
    [string]$drive_letter
  )

  # answer the customer's every need until the CPU melts or they say stop
  $is_finished = $false
  do {
    #while loop starts here
    if (([int]$type) -eq 0) {
      $command_name = $(Read-Host "What is the currently defined command?")
      Set-Alias $alias_name $command_name
      Write-Host "Success!"
      Write-Host "You can now use '$($alias_name)' in place of '$($command_name)' while running PowerShell"
      Write-Host "May the force be with you..."
      Export-Alias -Path $custom_aliases_path
      Add-CustomAliasInfo -alias_name $alias_name -command_name $command_name
      Restart-Shell
    } else if (([int]$type) -eq 1) {
      $filter = $(Read-Host "What keyword should we use to filter the search? (you can use * as wildcard)")
      $drive_letter = $(Read-Host "Enter a drive letter to search(~15s for 380GB) or press [Enter] to search all available drives (this may take a loooong time)")
      # getting the drives to search on
      $drives = Get-PSDrive
      if ($drive_letter -ne "") {
        $drives = @("$drive_letter")
      }

      $file_system_drives = @()
      if ($drives[0].GetType().Name -eq "String") {
        $file_system_drives = $drives
      } else {
        $drives = Get-PSDrive
        foreach ($drive in $drives) {
          if ($drive.Provider.ToString() -eq "Microsoft.PowerShell.Core\FileSystem") {
            $file_system_drives += $drive
          }
        }
      }

      $drive = $null

      # searching the drives recursively
      Write-Host "Searching $($file_system_drives) for '$filter'..........."
      $possible_matches = @()
      foreach ($drive in $file_system_drives) {
        Write-Host "Searching Drive $($drive): ......"
        $start = Get-Date -Verbose
        $result = Get-ChildItem -Path "$($drive):\" -Filter $filter -Recurse -ErrorAction SilentlyContinue
        $end = Get-Date -Verbose
        Write-Host "Search on drive '$($drive)' took this long: $($end - $start)"
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
        Add-CustomAliasInfo -alias_name $alias_name -command_name $alias_path
        Restart-Shell
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
}

Function Restart-Shell
{
  <#
    .PURPOSE
      * restarts the current powershell session
    .PARAMETERS
      * none
    .EXAMPLE
      * Restart-Shell
    .NOTES
      * this is useful for reloading the custom alias file
      * flags supported: -verbose, -debug
  #>
  PROCESS {
    Restart-Process -process "powershell"
  }
}

Function Restart-Process
{
  <#
  #>
  params {
    ## LAST_WORK!!
  }
  PROCESS {
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

Function Add-CustomAliasInfo
{
  <#
    .PURPOSE
      * Adds a new line to the given Table of Contents section (TODO)
    .PARAMETERS
      * [-alias_name [string-value]] [-command_name [string-value]] [-section [string-value]]
      * (string) -alias_name: the name of the alias for this entry
      * (string) -command_name: the name of the command or file that the alias is pointing to
      * (string) -section
        - [default] "aliases": the custom aliases section
        - "params": the global parameters section
        - "default": the default function section (not recommended)
  #>
  param(
    [parameter(Mandatory=$true)]
    [string]$alias_name = $(Read-Host "What will be the alias name for the entry?"),

    [parameter(Mandatory=$true)]
    [string]$command_name = $(Read-Host "What is the command name for the entry?"),

    [string]$section = $(Read-Host "What section should this be added to ('aliases', 'params', 'default')?")
  )
  BEGIN {
    WriteVerbose "Finding the file for the section specified";
  }
  PROCESS {
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

Function Remove-CustomAliasInfo
{
  param(
    [parameter(Mandatory=$true)]
    [string]$alias_name,

    [parameter(Mandatory=$true)]
    [string]$command_name
  )

  $new_line = "  * $($alias_name) : $($command_name)"

  if (202 -eq $(Search-CustomAliasInfo -key $alias_name -file_path $custom_help_path -action "remove") {
    # do nothing since it was found and replaced
  } else {
    if (Test-Path $custom_help_path) {
      Add-Content -Path $custom_help_path -Value $new_line
    }
  }
}


# PARAMETERS
# (string) $action : "remove", "replace"
# RETURN: a code that tells the caller what happened
# 200 : found the line and did nothing
# 201 : found the line and removed it
# 202 : found the line and replaced it
# 404 : didn't find the line
Function Search-CustomAliasInfo
{
  param(
    [parameter(Mandatory=$true)]
    [string]$key,

    [parameter(Mandatory=$true)]
    [string]$file_path,

    [string]$action,

    [string]$new_line
  )

  $return_code = 404

  # TODO: search for matches in $alias_name

  if (Test-Path $file_path) {
    $current_content = Get-Content $file_path
    $new_content = @()
    foreach ($line in $current_content) {
      if ($($line.StartsWith("  * $($key) :"))) {
        if ($action -eq "remove") {   # remove the line
          $return_code = 201
        } elseif ($action -eq "replace") {    # replace the line
          $new_content += $new_line
          $return_code = 202
        } else {
          $new_content += $line
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

# don't export everything!
# everything with a double underscore will be "private" to the module
# Export-ModuleMember -function @("_init", "Display-CustomAliasInfo", "Restart-Shell", "Set-CustomAlias", "Add-CustomAlias")

$Global:custom_aliases_path = "$($profile)\..\custom_aliases.txt"
$Global:toc_default = "$($profile)\..\toc_default.txt"
$Global:toc_aliases = "$($profile)\..\toc_aliases.txt"
$Global:toc_params = "$($profile)\..\toc_params.txt"

if (Test-Path $custom_aliases_path) {
  Import-Alias $custom_aliases_path -Scope Global -ErrorAction Ignore
}

Show-CustomHelp
