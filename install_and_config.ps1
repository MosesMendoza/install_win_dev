# Powershell specific argument passing
# You must be on the latest beta of chocolatey for this to work properly (redownload files)
# Based on https://gist.github.com/ferventcoder/947479688d930e28d632

$originalPath = $env:PATH

$rubyList = (@"
[
  {
    "choco_version": "1.9.3.55100",
    "uru_tag": "1.9.3",
    "target_dir": "c:\\tools\\ruby193",
    "32bit": true
  },  
  {
    "choco_version": "2.0.0.64800",
    "uru_tag": "2.0.0",
    "target_dir": "c:\\tools\\ruby200",
    "32bit": true,
    "64bit": true
  },
  {
    "choco_version": "2.1.8",
    "target_dir": "c:\\tools\\ruby21",
    "32bit": true,
    "64bit": true
  },
  {
    "choco_version": "2.2.4",
    "target_dir": "c:\\tools\\ruby22",
    "32bit": true,
    "64bit": true
  },
  {
    "choco_version": "2.3.0",
    "target_dir": "c:\\tools\\ruby23",
    "32bit": true,
    "64bit": true
  }
]
"@ | ConvertFrom-JSON -ErrorAction Stop)

if (get-command choco){
  Write-Output "Upgrading chocolately..."
# Prep
  choco upgrade chocolatey -pre -y
  choco feature enable -n=allowGlobalConfirmation -y
}
else {
  Write-Output "Installing chocolatey..."
  iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
}

choco install 7zip.commandline -y

# Install the various versions of ruby
$rubyList | Sort-Object -Property choco_version | % {
  $thisRuby = $_

  if ($thisRuby.'32bit') {
    choco.exe install ruby --version $($thisRuby.choco_version) -fmy -x86 --install-arguments "'/verysilent /dir=`"$($thisRuby.target_dir)`" /tasks=`"assocfiles`"'" --override-arguments
  }
  if ($thisRuby.'64bit') {
    choco.exe install ruby --version $($thisRuby.choco_version) -fmy --install-arguments "'/verysilent /dir=`"$($thisRuby.target_dir)-x64`" /tasks=`"assocfiles`"'" --override-arguments
  }
}

# Install the various ruby devkits
# Unfortunately devkit installs fail because ruby isn't on the path.
# Just run choco in a different process and ignore the return code.  Use simple file existence checks to see if it failedß
if ($rubyList | ? { $_.choco_version -match '^1\.'}) {
  Start-Process -FilePath 'choco' -ArgumentList (@('install','ruby.devkit','-y')) -NoNewWindow -Wait | Out-Null
  if (-not (Test-Path -Path 'C:\tools\devkit')) { Throw "DevKit did not install" }
}
if ($rubyList | ? { ($_.choco_version -match '^2\.') -and $_.'64bit' }) {
  Start-Process -FilePath 'choco' -ArgumentList (@('install','ruby2.devkit','-y')) -NoNewWindow -Wait | Out-Null
  if (-not (Test-Path -Path 'C:\tools\devkit2')) { Throw "DevKit 2.x x64 did not install" }
  Move-Item c:\tools\DevKit2 C:\tools\DevKit2-x64 -Force -EA Stop
}
if ($rubyList | ? { ($_.choco_version -match '^2\.') -and $_.'32bit' }) {
  Start-Process -FilePath 'choco' -ArgumentList (@('install','ruby2.devkit','-y','-x86','-f')) -NoNewWindow -Wait | Out-Null
  if (-not (Test-Path -Path 'C:\tools\devkit2')) { Throw "DevKit 2.x x86 did not install" }
}


# Install the various devkits into ruby
if ($rubyList | ? { $_.choco_version -match '^1\.'}) {
  Write-Output "Fixing DevKit 1.x installations"
  $lowestRuby = ($rubyList | ? { $_.choco_version -match '^1\.'} | Sort-Object -Property choco_version | Select-Object -First 1)

  $list = $rubyList | ? { $_.choco_version -match '^1\.'} | % { Write-Output "- $($_.target_dir.Replace('\','/'))" }
  "---`n`r" + ($list -join "`n`r") | Out-File c:\tools\DevKit\config.yml -Force -Encoding ASCII

  $env:PATH += ";$($lowestRuby.target_dir)\bin;"
  pushd c:\tools\DevKit
  ruby dk.rb install -f
  popd
  $env:PATH=$originalPath
}
if ($rubyList | ? { ($_.choco_version -match '^2\.') -and $_.'32bit' }) {
  Write-Output "Fixing DevKit 2.x 32bit installations"
  $lowestRuby = ($rubyList | ? { ($_.choco_version -match '^2\.') -and $_.'32bit' } | Sort-Object -Property choco_version | Select-Object -First 1)

  $list = $rubyList | ? { ($_.choco_version -match '^2\.') -and $_.'32bit' } | % { Write-Output "- $($_.target_dir.Replace('\','/'))" }
  "---`n`r" + ($list -join "`n`r") | Out-File c:\tools\DevKit2\config.yml -Force -Encoding ASCII

  $env:PATH += ";$($lowestRuby.target_dir)\bin;"
  pushd c:\tools\DevKit2
  ruby dk.rb install -f
  popd
  $env:PATH=$originalPath
}
if ($rubyList | ? { ($_.choco_version -match '^2\.') -and $_.'64bit' }) {
  Write-Output "Fixing DevKit 2.x 64bit installations"
  $lowestRuby = ($rubyList | ? { ($_.choco_version -match '^2\.') -and $_.'64bit' } | Sort-Object -Property choco_version | Select-Object -First 1)

  $list = $rubyList | ? { ($_.choco_version -match '^2\.') -and $_.'64bit' } | % { Write-Output "- $($_.target_dir.Replace('\','/'))-x64" }
  "---`n`r" + ($list -join "`n`r") | Out-File c:\tools\DevKit2-x64\config.yml -Force -Encoding ASCII

  $env:PATH += ";$($lowestRuby.target_dir)\bin;"
  pushd c:\tools\DevKit2-x64
  ruby dk.rb install -f
  popd
  $env:PATH=$originalPath
}

#TODO - get the certificate for rubygems installed ???

Write-Output "Remove ruby from the path..."
$regEnvPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
#$currentSysPath = 
$SysEnv = Get-ItemProperty -Path $regEnvPath
# Strip anything like 'C:\tools\rubyxxxxxxxx\bin' from the path list
$NewSysPath = ($SysEnv.Path) -split ';' | ? { (-not ( $_.ToUpper().StartsWith('C:\TOOLS\RUBY') -and $_.ToUpper().EndsWith('\BIN') )) }
Set-ItemProperty -Path $regEnvPath -Name 'Path' -Value ($NewSysPath -join ';') -Type ExpandString | Out-Null

# Install URU
Write-Output "Installing URU..."
$downloadURL = 'https://bitbucket.org/jonforums/uru/downloads/uru.0.8.1.nupkg'
$uruRoot = 'C:\Tools'
$uruInstall = Join-Path -Path $uruRoot -ChildPath 'URUInstall'
$uruInstallNuget = Join-Path -Path $uruInstall -ChildPath 'uru.0.8.1.nupkg'
if (Test-Path -Path $uruInstall) { Remove-Item -Path $uruInstall -Force -Recurse -Confirm:$false | Out-Null }
New-Item -Path $uruInstall -ItemType Directory | Out-Null
Write-Output "Downloading URU installer..."
(New-Object System.Net.WebClient).DownloadFile($downloadURL, $uruInstallNuget)

Write-Output "Running the URU installer..."
choco install uru -source $uruInstall -f -y

# Cleaning up...
if (Test-Path -Path $uruInstall) { Remove-Item -Path $uruInstall -Force -Recurse -Confirm:$false | Out-Null }

# Configure URU
$rubyList | Sort-Object -Property choco_version | % {
  $thisRuby = $_

  $tagName = $thisRuby.uru_tag
  if ($tagName -eq $null) { $tagName = $thisRuby.choco_version }

  if ($thisRuby.'32bit') {
   uru admin add "$($thisRuby.target_dir)\bin" --tag "$($tagName)-x86"
  }
  if ($thisRuby.'64bit') {
   uru admin add "$($thisRuby.target_dir)-x64\bin" --tag "$($tagName)-x64"
  }
}
# For confirmation...
uru list

# Now configure each ruby...
$rubyList | Sort-Object -Property choco_version | % {
  $tagName = $_.uru_tag
  if ($tagName -eq $null) { $tagName = $_.choco_version }
  if ($_.'32bit') { Write-Output "$($tagName)-x86" }
  if ($_.'64bit') { Write-Output "$($tagName)-x64" } 
} | % {
  Write-Host "------ Configuring $_ ..."

  uru $_
  Write-Output "Ruby version..."
  ruby -v
  Write-Output "Gem version..."
  gem -v
  Write-Output "Installing bundler..."
  # #gem install bundler --no-document -V  newer version
  gem install bundler --no-ri --no-rdoc -V

}


# Install other apps
Write-Output "Installing vim..."
choco install vim

Write-Output "Installing conemu..."
choco install conemu

Write-Output "Installing pry..."
uru 2.1.8-x64
gem install pry

Write-Output "Installing powershell update (with psreadline)"
choco install powershell

if (test-path .\Microsoft.PowerShell_profile.ps1) {
  Write-Output "Installing powershell profile"
  New-Item -path $profile -type file -force
  cp .\Microsoft.Powershell_profile.ps1 $profile
}


