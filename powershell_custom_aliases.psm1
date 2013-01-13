## powershell_custom_aliases.psm1 ##

Function _init
{
  Set-Location E:

  $custom_aliases_path = "$($profile)\..\custom_aliases.txt"
  $custom_help_path = "$($profile)\..\powershell_custom_table_of_contents.txt"

  if (Test-Path $custom_aliases_path) {
    Import-Alias $custom_aliases_path -Scope Global -ErrorAction Ignore
  }
  _displayCustomHelp
}

Function _displayCustomHelp
{
  $file = Get-Content $custom_help_path -ErrorAction Stop
  foreach ($line in $file) {
    Write-Host $line
  }
  Write-Host ""
  Write-Host ":END"
  Write-Host ""
}

# used for commands that are already in the global space
Function _setAlias
{
  param(
    [string]$alias_name = $(Read-Host "What will be the alias name?"),
    [string]$command_name = $(Read-Host "What is the currently defined command?")
  )

  Set-Alias $alias_name $command_name
  Write-Host "Success!"
  Write-Host "You can now use '$($alias_name)' in place of '$($command_name)' while running PowerShell"
  Write-Host "May the force be with you..."
  Export-Alias $custom_aliases_path
  __addCommandToCustomHelp -alias_name $alias_name -command_name $command_name
  _restartShell
}

# used for scripts and files that aren't already in the global space
Function _addAlias
{
  param(
    [string]$alias_name = $(Read-Host "What will be the alias name?"),
    [string]$filter = $(Read-Host "What keyword should we use to filter the search? (you can use * as wildcard)"),
    [string]$drive_letter = $($drive_letter = Read-Host "Enter a drive letter to search, or press [Enter] to search all available drives")
  )

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
    $result = Get-ChildItem -Path "$($drive):" -Filter $filter -Recurse -ErrorAction Ignore
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
    __addCommandToCustomHelp -alias_name $alias_name -command_name $alias_path
    _restartShell
  }
}

Function _restartShell
{
  $current_powershell = Get-Process -Name powershell
  Start-Process powershell
  Stop-Process $current_powershell
}

Function __addCommandToCustomHelp
{
  param(
    [parameter(Mandatory=$true)]
    [string]$alias_name,

    [parameter(Mandatory=$true)]
    [string]$command_name
  )

  $new_line = "  * $($alias_name) : $($command_name)"

  if (202 -eq $(__searchAndActionLine -key $alias_name -file_path $custom_help_path -action "replace" -new_line $new_line)) {
    # do nothing since it was found and replaced
  } else {
    if (Test-Path $custom_help_path) {
      Add-Content -Path $custom_help_path -Value $new_line
    }
  }
}

# returns a code that tells the caller what happened
# 200 : found the line and did nothing
# 201 : found the line and removed it
# 202 : found the line and replaced it
# 404 : didn't find the line
Function __searchAndActionLine
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

  # TODO: search for matches in $command_name and $alias_name

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
Export-ModuleMember -function @("_init", "_displayCustomHelp", "_restartShell", "_setAlias", "_addAlias")
