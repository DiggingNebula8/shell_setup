# ============================================================
# PowerShell 7 Configuration
# ============================================================

# Initialize Starship (with guard)
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ============================================================
# Module Imports (with guards for graceful degradation)
# ============================================================

$modules = @('Terminal-Icons', 'z', 'PSFzf', 'posh-git')
foreach ($module in $modules) {
    if (Get-Module -ListAvailable -Name $module) {
        Import-Module $module -ErrorAction SilentlyContinue
    }
}

# ============================================================
# PSReadLine Configuration (Better command-line editing)
# ============================================================

# Predictive IntelliSense
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

# History settings
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -MaximumHistoryCount 10000

# Key bindings
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord

# Colors
Set-PSReadLineOption -Colors @{
    Command   = 'Yellow'
    Parameter = 'Green'
    String    = 'DarkCyan'
}

# ============================================================
# PSFzf Configuration (Fuzzy finder)
# ============================================================

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# ============================================================
# Aliases
# ============================================================

# Navigation shortcuts
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# Better ls with icons
Set-Alias -Name ls -Value Get-ChildItem -Option AllScope
function ll { Get-ChildItem -Force | Format-Wide -Column 4 }
function la { Get-ChildItem -Force }

# Git shortcuts
function gs { git status }
function ga { git add $args }
function gc { git commit -m $args }
function gp { git push }
function gpl { git pull }
function gd { git diff }
function gco { git checkout $args }
function gb { git branch $args }
function glog { git log --oneline --graph --decorate --all }
function gclean { git clean -fd }
function gstash { git stash }
function gpop { git stash pop }

# Python shortcuts
function py { python $args }
function ipy { ipython }
function va { .\.venv\Scripts\Activate.ps1 }
function vd { deactivate }
function pipr { pip install -r requirements.txt }
function pipf { pip freeze | Out-File requirements.txt -Encoding UTF8 }

# Quick edit profile
function ep { notepad $PROFILE }
function rp { . $PROFILE }

# System utilities
function which($command) { Get-Command -Name $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path }
function touch($file) { "" | Out-File $file -Encoding ASCII }
function grep($pattern) { $input | Select-String $pattern }
function c { Clear-Host }
function path { $env:PATH -split ';' }
function myip { (Invoke-WebRequest -Uri 'https://ipinfo.io/ip' -UseBasicParsing).Content.Trim() }
function weather($location = '') { (Invoke-WebRequest -Uri "https://wttr.in/$location`?format=3" -UseBasicParsing).Content }  # empty = auto-detect

# ============================================================
# Custom Functions
# ============================================================

# Create and enter directory
function mkcd($dir) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Location $dir
}

# Find files by name
function find-file($name) {
    Get-ChildItem -Recurse -Filter "*$name*" -ErrorAction SilentlyContinue | Select-Object FullName
}

# Get disk usage
function disk-usage {
    Get-PSDrive -PSProvider FileSystem | 
    Select-Object Name, @{Name="Used(GB)";Expression={[math]::Round($_.Used/1GB,2)}}, 
                       @{Name="Free(GB)";Expression={[math]::Round($_.Free/1GB,2)}}, 
                       @{Name="Total(GB)";Expression={[math]::Round(($_.Used+$_.Free)/1GB,2)}}
}

# Quick project setup
function new-project($name) {
    mkcd $name
    git init
    python -m venv .venv
    .\.venv\Scripts\Activate.ps1
    New-Item requirements.txt
    New-Item README.md
    New-Item .gitignore
    @"
__pycache__/
*.py[cod]
.venv/
*.so
.env
"@ | Out-File .gitignore
    Write-Host "✓ Project '$name' created and initialized!" -ForegroundColor Green
}

# ============================================================
# Welcome Message
# ============================================================

Write-Host ""
Write-Host "PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)" -ForegroundColor Cyan
Write-Host "Type 'help-aliases' for custom commands" -ForegroundColor Gray
Write-Host ""

function help-aliases {
    Write-Host "`n=== Navigation ===" -ForegroundColor Yellow
    Write-Host "  ..      - Go up one directory"
    Write-Host "  ...     - Go up two directories"
    Write-Host "  ....    - Go up three directories"
    Write-Host "  mkcd    - Create and enter directory"
    
    Write-Host "`n=== File Listing ===" -ForegroundColor Yellow
    Write-Host "  ls      - List files"
    Write-Host "  ll      - Wide format list"
    Write-Host "  la      - List all including hidden"
    
    Write-Host "`n=== Git ===" -ForegroundColor Yellow
    Write-Host "  gs      - git status"
    Write-Host "  ga      - git add"
    Write-Host "  gc      - git commit -m"
    Write-Host "  gp      - git push"
    Write-Host "  gpl     - git pull"
    Write-Host "  gd      - git diff"
    Write-Host "  gco     - git checkout"
    Write-Host "  gb      - git branch"
    Write-Host "  glog    - Pretty git log"
    Write-Host "  gstash  - git stash"
    Write-Host "  gpop    - git stash pop"
    Write-Host "  gclean  - git clean -fd"
    
    Write-Host "`n=== Python ===" -ForegroundColor Yellow
    Write-Host "  py      - python"
    Write-Host "  ipy     - ipython"
    Write-Host "  va      - Activate .venv"
    Write-Host "  vd      - Deactivate venv"
    Write-Host "  pipr    - pip install -r requirements.txt"
    Write-Host "  pipf    - pip freeze > requirements.txt"
    
    Write-Host "`n=== Search & Find ===" -ForegroundColor Yellow
    Write-Host "  find-file - Find files by name"
    Write-Host "  grep      - Search pattern in input"
    
    Write-Host "`n=== Utilities ===" -ForegroundColor Yellow
    Write-Host "  c         - Clear screen"
    Write-Host "  path      - Show PATH entries"
    Write-Host "  which     - Find command path"
    Write-Host "  touch     - Create empty file"
    Write-Host "  myip      - Get public IP"
    Write-Host "  weather   - Get weather forecast"
    Write-Host "  disk-usage - Show disk usage"
    Write-Host "  new-project - Create new Python project"
    
    Write-Host "`n=== Config ===" -ForegroundColor Yellow
    Write-Host "  ep      - Edit profile"
    Write-Host "  rp      - Reload profile"
    Write-Host ""
}