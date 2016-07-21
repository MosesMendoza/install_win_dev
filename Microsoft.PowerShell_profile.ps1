# Aliases
new-item alias:vi -value vim

function be { bundle exec $args }

# git shortcuts
function cm { git commit -m $args }
function ca { git commit --amend -CHEAD }
function add { git add $args }
function status { git status }
function dh { git diff HEAD }
function lg { git lg }

# extend Path to include process monitor and process explorer

$env:Path += ";C:\Tools\ProcessTools"

# Set default ruby to 2.1.8 as this is LCD for Puppet
uru 2.1.8-x64

# This prepends this path to RUBYLIB for requiring 'puppet'
$env:RUBYLIB='C:/Users/moses/development/puppet/lib'

# All for posh-git
if(Test-Path Function:\Prompt) {Rename-Item Function:\Prompt PrePoshGitPrompt -Force}

# Load posh-git example profile
. 'C:\tools\poshgit\dahlbyk-posh-git-5ed5c05\profile.example.ps1'

Rename-Item Function:\Prompt PoshGitPrompt -Force
function Prompt() {if(Test-Path Function:\PrePoshGitPrompt){++$global:poshScope; New-Item function:\script:Write-host -value "param([object] `$object, `$backgroundColor, `$foregroundColor, [switch] `$nonewline) " -Force | Out-Null;$private:p = PrePoshGitPrompt; if(--$global:poshScope -eq 0) {Remove-Item function:\Write-Host -Force}}PoshGitPrompt}

# Disable git file status
$GitPromptSettings.EnableFileStatus = $false
$GitPromptSettings.BeforeText = "("
$GitPromptSettings.AfterText = ")"


# Set up bash readline-like behaviors
Import-Module PSReadline

Set-PSReadlineKeyHandler -Chord Ctrl+a -Function BeginningOfLine
Set-PSReadlineKeyHandler -Chord Ctrl+e -Function EndOfLine
Set-PSReadlineKeyHandler -Chord Ctrl+k -Function KillLine
Set-PSReadlineKeyHandler -Chord Ctrl+f -Function NextWord
Set-PSReadlineKeyHandler -Chord Ctrl+b -Function BackwardWord

# Make sure we can access vmware shared drive from command line

if (-Not(get-item Z:)) {
  net use Z: "\\vmware-host\Shared Folders" /YES
}

# Clear up the console
Clear-Host
