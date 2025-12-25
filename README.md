# Modern Windows + WSL2 Development Environment Setup

> **Purpose**: Configure a professional dual-environment setup for Python development on Windows and Linux (WSL2).
>
> **Target Audience**: Developers who need flexibility between Windows-native and Linux-based workflows.
>
> **Estimated Time**: 60-90 minutes (including restart and shell customization)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Part 1: Windows Host Configuration](#part-1-windows-host-configuration)
3. [Part 2: WSL2 & Debian Setup](#part-2-wsl2--debian-setup)
4. [Part 3: Python Version Management](#part-3-python-version-management)
5. [Part 4: Git & SSH Configuration](#part-4-git--ssh-configuration)
6. [Part 5: VS Code WSL Integration](#part-5-vs-code-wsl-integration)
7. [Part 6: Advanced Shell Configuration](#part-6-advanced-shell-configuration)
8. [Part 7: Standard Development Workflows](#part-7-standard-development-workflows)
9. [Troubleshooting](#troubleshooting)
10. [Maintenance & Updates](#maintenance--updates)
11. [Next Steps](#next-steps)
12. [Additional Resources](#additional-resources)

---

## Prerequisites

- Windows 10 (version 2004+) or Windows 11
- Administrator access
- Stable internet connection
- At least 10GB free disk space

---

## Part 1: Windows Host Configuration

### 1.1 Install PowerShell 7

**Why**: Windows PowerShell 5.1 is deprecated. PowerShell 7 is cross-platform and actively maintained.

**Environment**: Windows Command Prompt or PowerShell 5.1  
**Privilege**: Administrator

```powershell
winget install --id Microsoft.PowerShell --source winget
```

**Verification**: Close and reopen PowerShell, then run:

```powershell
$PSVersionTable.PSVersion
# Should show version 7.x.x
```

---

### 1.2 Install Package Manager (Scoop)

**Why**: Scoop manages Windows development tools cleanly in user space (no admin required after setup).

**Environment**: PowerShell 7  
**Privilege**: User

```powershell
# Allow running downloaded scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install Scoop
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# CRITICAL: Install Git first (required for bucket support)
scoop install git

# Add software repositories
scoop bucket add extras
scoop bucket add nerd-fonts

# Install development tools
scoop install starship CascadiaCode-NF-Mono python
```

**Verification**:

```powershell
scoop list
# Should show git, starship, etc.
```

---

### 1.3 Configure Windows Terminal Font

**Why**: Nerd Fonts include programming ligatures and icons used by modern shell themes.

1. Open **Windows Terminal** (press `Ctrl + ,` for settings)
2. Select **PowerShell** profile from the left sidebar
3. Navigate to **Appearance** tab
4. Set **Font face** to `CascadiaCode NF Mono`
5. Click **Save**

---

### 1.4 Enable Starship Prompt Theme

**Why**: Starship provides a fast, informative shell prompt showing git status, Python version, etc.

**Environment**: PowerShell 7  
**Privilege**: User

```powershell
# Create/edit PowerShell profile
notepad $PROFILE
```

Add this line to the file and save:

```powershell
Invoke-Expression (&starship init powershell)
```

**Verification**: Restart PowerShell. You should see a styled prompt with context-aware information.

---

> ⚠️ **REQUIRED**: Install VSCode from Installer, not Scoop.

## Part 2: WSL2 & Debian Setup

### 2.1 Install WSL2 with Debian

**Why**: WSL2 provides a native Linux kernel for true compatibility with Linux tools and workflows.

**Environment**: PowerShell 7  
**Privilege**: Administrator

```powershell
# Install Debian distribution
wsl --install -d Debian

# Update WSL kernel to latest version
wsl --update
```

> ⚠️ **REQUIRED**: Restart your computer after this step.

After restart, open **Debian** from the Start menu to complete first-time setup:
- Create a Linux username (can differ from Windows username)
- Create a Linux password (you'll need this for `sudo` commands)

**Verification**:

```powershell
wsl --list --verbose
# Should show Debian with WSL version 2
```

---

### 2.2 Update Debian and Install Build Dependencies

**Why**: These packages are required to compile Python from source and build native extensions.

**Environment**: Debian (Bash in WSL)  
**Privilege**: User (with sudo)

```bash
# Update package lists and upgrade system
sudo apt update && sudo apt upgrade -y

# Install Python build dependencies
sudo apt install -y \
  curl \
  git \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  libffi-dev \
  liblzma-dev
```

**Verification**:

```bash
gcc --version
# Should show GCC compiler version
```

---

### 2.3 Install Starship Theme (Linux)

**Environment**: Debian (Bash)  
**Privilege**: User

```bash
# Download and install Starship binary
curl -sS https://starship.rs/install.sh | sh

# Add initialization to bash profile
echo 'eval "$(starship init bash)"' >> ~/.bashrc

# Apply changes
source ~/.bashrc
```

**Verification**: You should see a styled prompt matching your Windows PowerShell theme.

---

## Part 3: Python Version Management

### Windows: Use Scoop Python

On Windows, use the Python version installed via Scoop (step 1.2). Update it with:

```powershell
scoop update python
```

### Linux: Use pyenv for Version Management

**Why**: pyenv allows installing multiple Python versions side-by-side and switching between them per-project.

**Environment**: Debian (Bash)  
**Privilege**: User

```bash
# Install pyenv
curl https://pyenv.run | bash

# Add pyenv to PATH and initialize (append to .bashrc)
cat >> ~/.bashrc << 'EOF'
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF

# Reload shell configuration
source ~/.bashrc

# Install Python 3.12.0
pyenv install 3.12.0

# Set as global default
pyenv global 3.12.0
```

**Verification**:

```bash
python --version
# Should show Python 3.12.0

pyenv versions
# Should list installed versions with * next to active one
```

---

## Part 4: Git & SSH Configuration

### 4.1 Generate SSH Key (Windows)

**Why**: SSH keys provide secure, passwordless authentication to Git services (GitHub, GitLab, etc.).

**Environment**: PowerShell 7  
**Privilege**: User

```powershell
# Generate Ed25519 key (modern, secure algorithm)
ssh-keygen -t ed25519 -C "your_email@example.com"

# When prompted:
# - Press Enter to accept default location (~/.ssh/id_ed25519)
# - Enter a strong passphrase (recommended) or press Enter for no passphrase
```

**Important**: Copy the public key to your clipboard:

```powershell
Get-Content ~/.ssh/id_ed25519.pub | Set-Clipboard
```

Then add it to your Git service:
- **GitHub**: Settings → SSH and GPG keys → New SSH key
- **GitLab**: Preferences → SSH Keys → Add new key

---

### 4.2 Copy SSH Keys to Linux

**Why**: Using the same SSH key in both environments prevents identity conflicts.

**Environment**: Debian (Bash)  
**Privilege**: User

```bash
# Create .ssh directory
mkdir -p ~/.ssh

# Copy keys from Windows user directory (adjust username if needed)
cp /mnt/c/Users/YourUsername/.ssh/id_ed25519* ~/.ssh/

# Set correct permissions (SSH requires these exact permissions)
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

**Verification**:

```bash
ls -la ~/.ssh
# Should show proper permissions: drwx------ for directory, -rw------- for private key
```

---

### 4.3 Configure Git Identity

**Run in BOTH PowerShell (Windows) and Bash (Linux)**:

```bash
git config --global user.name "Your Full Name"
git config --global user.email "your_email@example.com"

# Optional but recommended settings
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.autocrlf input  # For cross-platform line endings
```

**Verification**:

```bash
git config --global --list
```

---

## Part 5: VS Code WSL Integration

### 5.1 Install Remote-WSL Extension

**Why**: This allows your Windows VS Code installation to seamlessly edit files in WSL, with full IntelliSense and debugging support.

**Steps:**

1. **Open VS Code on Windows** (from Start menu or run `code` in PowerShell)

2. **Install the Remote-WSL Extension:**
   - Press `Ctrl+Shift+X` to open Extensions marketplace
   - Search for "**WSL**"
   - Install "**WSL**" by Microsoft (Extension ID: `ms-vscode-remote.remote-wsl`)

3. **Install Additional Recommended Extensions:**
   - **Python** (Microsoft) - `ms-python.python`
   - **Pylance** (Microsoft) - `ms-python.vscode-pylance`
   - **GitLens** - `eamodio.gitlens`

---

### 5.2 Configure VS Code PATH in WSL

**Environment**: Debian (Bash)  
**Privilege**: User

Add VS Code to your WSL PATH so you can open files from the terminal:

```bash
# Add VS Code to PATH (adjust username if needed)
echo 'export PATH="$PATH:/mnt/c/Users/YourUsername/scoop/apps/vscode/current/bin"' >> ~/.bashrc

# Reload configuration
source ~/.bashrc
```

**Verification**:

```bash
# Should open VS Code connected to WSL
code .

# Should show the path
which code
```

> **Note**: When you run `code .` from WSL, it will automatically open VS Code on Windows with the Remote-WSL extension connected to your Linux environment.

---

### 5.3 Configure Python Interpreter in VS Code

Once VS Code is connected to WSL:

1. Open Command Palette (`Ctrl+Shift+P`)
2. Type "**Python: Select Interpreter**"
3. Choose the interpreter from your `.venv` folder or pyenv installation

---

## Part 6: Advanced Shell Configuration

### 6.1 PowerShell Enhancements

#### Install Essential PowerShell Modules

**Environment**: PowerShell 7  
**Privilege**: User

```powershell
# PSReadLine - Better command line editing
Install-Module -Name PSReadLine -Force -SkipPublisherCheck

# Terminal-Icons - File/folder icons in ls
Install-Module -Name Terminal-Icons -Repository PSGallery -Force

# z - Smart directory jumping
Install-Module -Name z -Force

# PSFzf - Fuzzy finder integration
scoop install fzf
Install-Module -Name PSFzf -Force

# posh-git - Enhanced git integration
Install-Module -Name posh-git -Force
```

#### Enhanced PowerShell Profile

Edit your profile: `notepad $PROFILE`

```powershell
# ============================================================
# PowerShell 7 Configuration
# ============================================================

# Initialize Starship
Invoke-Expression (&starship init powershell)

# ============================================================
# Module Imports
# ============================================================

Import-Module Terminal-Icons
Import-Module z
Import-Module PSFzf
Import-Module posh-git

# ============================================================
# PSReadLine Configuration
# ============================================================

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -MaximumHistoryCount 10000

# Key bindings
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# ============================================================
# PSFzf Configuration
# ============================================================

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# ============================================================
# Aliases & Functions
# ============================================================

# Navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }

# Git shortcuts
function gs { git status }
function ga { git add $args }
function gc { git commit -m $args }
function gp { git push }
function gpl { git pull }
function glog { git log --oneline --graph --decorate --all }

# Python shortcuts
function py { python $args }
function va { .\.venv\Scripts\Activate.ps1 }
function vd { deactivate }

# Utilities
function which($command) { 
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty Path 
}

# Create and enter directory
function mkcd($dir) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Location $dir
}

# Quick project setup
function new-project($name) {
    mkcd $name
    git init
    python -m venv .venv
    .\.venv\Scripts\Activate.ps1
    New-Item requirements.txt, README.md, .gitignore
    @"
__pycache__/
*.py[cod]
.venv/
*.so
.env
"@ | Out-File .gitignore
    Write-Host "✓ Project '$name' created!" -ForegroundColor Green
}

# Help command
function help-aliases {
    Write-Host "`n=== Navigation ===" -ForegroundColor Yellow
    Write-Host "  ..       - Up one directory"
    Write-Host "  mkcd     - Create and enter directory"
    Write-Host "`n=== Git ===" -ForegroundColor Yellow
    Write-Host "  gs/ga/gc - status/add/commit"
    Write-Host "  gp/gpl   - push/pull"
    Write-Host "  glog     - Pretty log"
    Write-Host "`n=== Python ===" -ForegroundColor Yellow
    Write-Host "  va/vd    - Activate/deactivate venv"
    Write-Host ""
}

Write-Host ""
Write-Host "PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "Type 'help-aliases' for shortcuts" -ForegroundColor Gray
Write-Host ""
```

Apply changes: Close and reopen PowerShell

---

### 6.2 Bash Enhancements (WSL)

#### Install Modern CLI Tools

**Environment**: Debian (Bash)  
**Privilege**: User (with sudo)

```bash
# Install modern replacements for classic tools
sudo apt install -y \
  fzf \           # Fuzzy finder
  bat \           # Better cat
  exa \           # Better ls
  ripgrep \       # Better grep
  fd-find \       # Better find
  tldr \          # Simple man pages
  htop \          # Better top
  ncdu            # Disk usage

# Install autojump (smart directory navigation)
sudo apt install -y autojump
```

#### Enhanced Bash Configuration

Edit `~/.bashrc`:

```bash
# ~/.bashrc - cleaned and reorganized
# Keeps original behavior; added guards and documentation

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# --------------------------
# Debian chroot (prompt helper)
# --------------------------
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# --------------------------
# History configuration
# --------------------------
# Increase history size and avoid duplicates
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s cmdhist     # save multi-line commands as one

# --------------------------
# Shell options (shopt)
# --------------------------
shopt -s checkwinsize  # update LINES & COLUMNS after each command
shopt -s cdspell       # autocorrect minor typos in chdir
shopt -s globstar      # ** recursive globbing

# --------------------------
# Prompt & colors
# --------------------------
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if command -v tput >/dev/null 2>&1 && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# --------------------------
# Environment & tools init
# --------------------------
# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

# Starship (single init with guard)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# Fastfetch (optional system summary)
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# --------------------------
# dircolors & ls (colors)
# --------------------------
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Prefer exa if available, otherwise fallback to ls --color
if command -v exa &> /dev/null; then
    alias ls='exa --icons --group-directories-first'
    alias ll='exa -lah --icons --group-directories-first'
    alias la='exa -a --icons --group-directories-first'
    alias lt='exa --tree --level=2 --icons'
else
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
fi

# --------------------------
# Better tools aliases (bat, rg, fd)
# --------------------------
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias catt='bat'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
fi

if command -v fdfind &> /dev/null; then
    alias fd='fdfind'
fi

# --------------------------
# Aliases: navigation, git, python, system
# --------------------------
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate --all'
alias gclean='git clean -fd'
alias gstash='git stash'
alias gpop='git stash pop'

# Python
alias py='python3'
alias ipy='ipython'
alias va='source .venv/bin/activate'
alias vd='deactivate'
alias pipr='pip install -r requirements.txt'
alias pipf='pip freeze > requirements.txt'

# System
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias ports='netstat -tulanp'
alias update='sudo apt update && sudo apt upgrade -y'

# Quick edits
alias bashrc='nano ~/.bashrc'
alias reload='source ~/.bashrc'

# --------------------------
# Custom functions
# --------------------------
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

ff() { find . -type f -iname "*$1*"; }
fd() { find . -type d -iname "*$1*"; }

new-project() {
    local name="$1"
    mkcd "$name"
    git init
    python3 -m venv .venv
    source .venv/bin/activate
    touch requirements.txt README.md
    cat > .gitignore << EOF
__pycache__/
*.py[cod]
.venv/
*.so
.env
EOF
    echo "✓ Project '$name' created and initialized!"
}

myip() {
    curl -s https://ipinfo.io/ip
}

weather() {
    curl -s "wttr.in/${1:-Bangalore}?format=3"
}

# --------------------------
# FZF (with ripgrep & sensible defaults)
# --------------------------
if command -v fzf &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_DEFAULT_OPTS='
        --height 40%
        --layout=reverse
        --border
        --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
        --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
        --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
        --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'
    [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
fi

# --------------------------
# Autojump
# --------------------------
if [ -f /usr/share/autojump/autojump.sh ]; then
    source /usr/share/autojump/autojump.sh
fi

# --------------------------
# Man page colors
# --------------------------
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

# --------------------------
# Welcome message & help
# --------------------------
echo ""
echo -e "\e[36mBash $(bash --version | head -n1 | cut -d' ' -f4 | cut -d'(' -f1)\e[0m"
echo -e "\e[90mType 'help-aliases' for custom commands\e[0m"
echo ""

help-aliases() {
    echo -e "\n\e[33m=== Navigation ===\e[0m"
    echo "  ..     - Go up one directory"
    echo "  ...    - Go up two directories"
    echo "  mkcd   - Create and enter directory"
    echo "  j      - Jump to directory (autojump)"
    
    echo -e "\n\e[33m=== Git ===\e[0m"
    echo "  gs     - git status"
    echo "  ga     - git add"
    echo "  gc     - git commit -m"
    echo "  gp     - git push"
    echo "  glog   - Pretty git log"
    
    echo -e "\n\e[33m=== Python ===\e[0m"
    echo "  py     - python3"
    echo "  va     - Activate .venv"
    echo "  vd     - Deactivate venv"
    
    echo -e "\n\e[33m=== Utilities ===\e[0m"
    echo "  extract - Extract any archive"
    echo "  ff      - Find files"
    echo "  myip    - Get public IP"
    echo "  weather - Get weather forecast"
    echo ""
}

```

Apply changes:

```bash
source ~/.bashrc
```

---

### 6.3 Starship Custom Configuration

Create a custom Starship theme that works in both environments. Create seperately or create a SYMLINK

**Location**: `~/.config/starship.toml` (Windows and Linux)

```bash
# Linux: Create config
mkdir -p ~/.config && nano ~/.config/starship.toml

# Windows PowerShell: Create config
mkdir -Force ~/.config; notepad ~/.config/starship.toml
```

**Recommended Configuration**:

```toml
# ~/.config/starship.toml

# Faster prompt (don't wait for command timeout)
command_timeout = 500

# Customize prompt format
format = """
[+--](bold green)$username$hostname$directory$git_branch$git_status$python$nodejs$rust$golang
[--](bold green)$character"""

# Show username only when SSH
[username]
show_always = false
format = "[$user]($style)@"
style_user = "bold blue"

# Show hostname only when SSH
[hostname]
ssh_only = true
format = "[$hostname]($style) "
style = "bold blue"

# Directory settings
[directory]
truncation_length = 3
truncate_to_repo = true
format = "[$path]($style)[$read_only]($read_only_style) "
style = "bold cyan"

# Git branch
[git_branch]
symbol = " "
format = "on [$symbol$branch]($style) "
style = "bold purple"

# Git status
[git_status]
format = '([[$all_status$ahead_behind]]($style) )'
style = "bold red"
conflicted = "!"
ahead = "^${count}"
behind = "v${count}"
diverged = "<>${ahead_count}/${behind_count}"
untracked = "?${count}"
stashed = "stash"
modified = "!${count}"
staged = "+${count}"
renamed = "ren${count}"
deleted = "x${count}"

# Python version
[python]
symbol = " "
format = 'via [$symbol$pyenv_prefix($version )(($virtualenv) )]($style)'
style = "yellow bold"
pyenv_version_name = false
detect_extensions = ["py"]

# Node.js
[nodejs]
symbol = " "
format = "via [$symbol($version )]($style)"
style = "bold green"

# Rust
[rust]
symbol = " "
format = "via [$symbol($version )]($style)"
style = "bold red"

# Go
[golang]
symbol = " "
format = "via [$symbol($version )]($style)"
style = "bold cyan"

# Character (prompt symbol)
[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"
vicmd_symbol = "[<](bold green)"

# Command duration
[cmd_duration]
min_time = 2000
format = "took [$duration]($style) "
style = "bold yellow"

# Time
[time]
disabled = false
format = '[[ $time ]]($style) '
time_format = "%T"
style = "bold white"
```

---

## Part 7: Standard Development Workflows

### When to Use Each Environment

| Use Windows (PowerShell) | Use Linux (WSL2/Debian) |
|--------------------------|-------------------------|
| Windows-specific development | Backend/server development |
| .NET or Windows GUI apps | Data science/ML workflows |
| Native Windows scripting | Docker containers |
| Testing on Windows | Shell scripting (bash) |

---

### Workflow A: Linux Development (Recommended)

**Environment**: Debian (Bash)

```bash
# Navigate to home
cd ~

# Create project
mkdir my_project && cd my_project

# Initialize git
git init

# Create virtual environment
python -m venv .venv

# Activate
source .venv/bin/activate

# Install packages
pip install --upgrade pip
pip install requests pandas numpy

# Save dependencies
pip freeze > requirements.txt

# Open in VS Code (connected to WSL)
code .
```

**Deactivate**: `deactivate`

---

### Workflow B: Windows Development

**Environment**: PowerShell 7

```powershell
# Navigate to projects
cd ~\Documents
mkdir my_win_project
cd my_win_project

# Initialize git
git init

# Create virtual environment
python -m venv .venv

# Activate
.\.venv\Scripts\Activate.ps1

# Install packages
pip install --upgrade pip
pip install requests pandas

# Save dependencies
pip freeze > requirements.txt

# Open in VS Code
code .
```

**Deactivate**: `deactivate`

---

## Troubleshooting

### Issue: `code .` shows "Exec format error" in WSL

**Solution**: Make sure you've completed Part 5.2 to add VS Code to WSL PATH and installed the Remote-WSL extension.

### Issue: `scoop install` fails with "Couldn't find manifest"

**Solution**: Ensure Git was installed first: `scoop install git`

### Issue: WSL2 won't start after installation

**Solution**: Enable virtualization in BIOS and run: `wsl --set-default-version 2`

### Issue: SSH key permissions error in WSL

**Solution**: Re-run the chmod commands exactly as shown in section 4.2

### Issue: Python command not found after pyenv install

**Solution**: Reload shell with `source ~/.bashrc` or restart terminal

### Issue: VS Code can't find Python interpreter

**Solution**: Make sure virtual environment is activated, then reload VS Code window (`Ctrl+Shift+P` → "Developer: Reload Window")

### Issue: PowerShell modules fail to import

**Solution**: Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Maintenance & Updates

### Update Windows Tools

```powershell
scoop update *
```

### Update Debian Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### Update Python Versions (Linux)

```bash
pyenv update
pyenv install 3.12.x
pyenv global 3.12.x
```

### Update PowerShell Modules

```powershell
Update-Module -Name PSReadLine, Terminal-Icons, z, PSFzf, posh-git
```

---

## Next Steps

1. **Test Your Setup**: Create a test project in both environments
2. **Backup Configurations**: Save your dotfiles (`.bashrc`, `$PROFILE`, `starship.toml`)
3. **Explore Tools**: Try `fzf` (Ctrl+R), `bat`, `exa`, and other modern CLI tools
4. **Learn Shortcuts**: Master the aliases you've added (`gs`, `va`, `mkcd`, etc.)
5. **Customize Further**: Adjust Starship theme colors and add more aliases

---

## Keyboard Shortcuts Reference

```
=== Navigation ===
Ctrl+R        Search command history (fzf)
Ctrl+T        Search files (fzf)
cd -          Previous directory
j <dir>       Jump to directory (autojump)

=== Editing ===
Ctrl+A        Beginning of line
Ctrl+E        End of line
Ctrl+U        Delete to beginning
Ctrl+K        Delete to end
Alt+B/F       Move by word

=== VS Code ===
Ctrl+Shift+P  Command palette
Ctrl+`        Toggle terminal
Ctrl+B        Toggle sidebar
```

---

## Additional Resources

- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [Scoop Package Manager](https://scoop.sh/)
- [WSL Documentation](https://docs.microsoft.com/windows/wsl/)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/wsl)
- [pyenv Documentation](https://github.com/pyenv/pyenv)
- [Starship Prompt](https://starship.rs/)
- [Modern Unix Tools](https://github.com/ibraheemdev/modern-unix)
- [Git Best Practices](https://git-scm.com/book/en/v2)

---

## License

This documentation is provided as-is for educational purposes. Feel free to adapt it to your needs.

---

**Last Updated**: December 2025  
**Version**: 2.0
