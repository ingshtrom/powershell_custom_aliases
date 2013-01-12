Set-Location E:

$drives = $null
$alias_export_path = '.\alias_export.xml'

Function displayCustomHelp
{
  $file = Get-Content C:\Users\ingsh_000\Documents\WindowsPowerShell\powershell_menu.txt
  foreach ($line in $file) {
    Write-Host $line
  }
}

Function Add-Alias
{
  [CmdletBinding()]
  param(
    [string]$alias,
    [string]$filter,
    [string]$drive
  )

  $alias_name = $alias
  $drive_letter = $drive

  # make sure all necessary information is gathered
  if ($alias_name -eq '') {
    $alias_name = Read-Host "What will be the alias name?"
  }

  if ($filter -eq '') {
    $filter = Read-Host "What keyword should we filter on? (you can use * as wildcard)"
  }

  if ($drive_letter -eq '') {
    $drive_letter = Read-Host "Enter a drive letter to search, or press [Enter] to search all available drives"
  }

  # getting the drives to search on
  $drives = Get-PSDrive
  Write-Host $drives.GetType()
  Write-Host $drives[0].GetType()
  if ($drive_letter -ne "") {
    $drives = @("$drive_letter")
  }
  Write-Host $drives.GetType()
  Write-Host $drives[0].GetType()

  $file_system_drives = @()
  if ($drives[0].GetType().Name -eq "String") {
    $file_system_drives = $drives
  } else {
    Write-Host $drives.GetType()
    Write-Host $drives[0].GetType()
    $drives = Get-PSDrive
    Write-Host $drives.GetType()
    Write-Host $drives[0].GetType()
    foreach ($drive in $drives) {
      write-host $drive.GetType()
      if ($drive.Provider.ToString() -eq "Microsoft.PowerShell.Core\FileSystem") {
        $file_system_drives += $drive
      }
    }
  }

  # searching the drives recursively
  Write-Host "Searching $($drives) for '$filter'..........."
  $possible_matches = @()
  foreach ($drive in $file_system_drives) {
    Write-Host "Searching Drive $($drive): ......"
    $result = Get-ChildItem -Path "$($drive):" -Filter $filter -Recurse
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

  # output final results
  if($answer -eq "0") {
    Write-Host "I'm sorry this didn't work. Maybe the file you are looking for...doesn't exist."
  } else {
    $answer *= 1
    Set-Alias $alias_name $possible_matches[$answer]
    Write-Host "Success!"
    Write-Host "You can now use '$($alias_name)' in place of '$($possible_matches[$answer])' while running PowerShell"
    Write-Host "May the force be with you..."
  }
}

Function _saveAliasBindings
{
  param(
    [Parameter(required)]
    [string]$destination_path
  )
}

Function _loadAliasBindings
{

}

displayCustomHelp

# programs
Set-Alias chrome 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
Set-Alias dartium 'D:\Programs\dart\chromium\chrome.exe'
Set-Alias steam 'E:\Program Files\Steam\Steam.exe'
Set-Alias darte 'D:\Programs\dart\DartEditor.exe'
Set-Alias github 'C:\Users\ingsh_000\AppData\Local\GitHub\GitHub.appref-ms'
Set-Alias itunes 'D:\Programs\iTunes\iTunes.exe'
Set-Alias vs 'D:\Programs\Microsoft Visual Studio 11.0\Common7\IDE\WDExpress.exe'
Set-Alias unity 'D:\Programs\Unity\Editor\Unity.exe'
Set-Alias sublime 'D:\Programs\Sublime Text 2\sublime_text.exe'
# scripts
Set-Alias dart 'D:\Programs\dart\dart-sdk\bin\dart.exe'
Set-Alias darta 'D:\Programs\dart\dart-sdk\bin\dart_analyzer.bat'
Set-Alias dart2js 'D:\Programs\dart\dart-sdk\bin\dart2js.bat'
Set-Alias dartd 'D:\Programs\dart\dart-sdk\bin\dartdoc.bat'
Set-Alias dartp 'D:\Programs\dart\dart-sdk\bin\pub.bat'
Set-Alias git 'D:\Programs\Git\bin\git.exe'
# games
Set-Alias gw2 'D:\Programs\Guild Wars 2\gw2.exe'
Set-Alias cavestory 'D:\Programs\Cave Story\CaveStory\Doukutsu.exe'
Set-Alias swtor 'D:\Programs\Star Wars-The Old Republic\launcher.exe'

