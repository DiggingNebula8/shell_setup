Development Environment Setup Guide: Windows 11 and Debian WSL
This document outlines the configuration for a dual-environment development stack using PowerShell 7 and Debian (WSL2).

Phase 1: Windows Side (Host Environment)
1. PowerShell 7 and Scoop
PowerShell

# [ADMIN] Install modern PowerShell
winget install --id Microsoft.PowerShell --source winget

# [USER] Set execution policy for scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# [USER] Install Scoop Package Manager
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# [USER] Add required buckets
scoop bucket add extras
scoop bucket add nerd-fonts

# [USER] Install core utilities and fonts
scoop install git vscode starship CascadiaCode-NF-Mono python
2. Windows Customization
Font: Open Windows Terminal Settings > Profiles > PowerShell > Appearance. Set Font face to Cascadia Code NF Mono.

Prompt: Initialize Starship theme.

PowerShell

# [USER] Edit PowerShell Profile
notepad $PROFILE

# Add the following line to the end of the file:
Invoke-Expression (&starship init powershell)
Phase 2: Linux Side (Debian WSL)
1. WSL Activation
PowerShell

# [ADMIN] Install Debian distribution
wsl --install -d Debian

# [ADMIN] Update WSL Kernel
wsl --update
Note: A system restart is required after these commands.

2. Debian Initialization
Bash

# [USER] Update package lists
sudo apt update && sudo apt upgrade -y

# [USER] Install dependencies for building Python
sudo apt install -y curl build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev git \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
3. Python Version Management (pyenv)
Bash

# [USER] Install pyenv
curl https://pyenv.run | bash

# [USER] Configure Bash for pyenv (Add to ~/.bashrc)
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
source ~/.bashrc

# [USER] Install and set global Python
pyenv install 3.12.0
pyenv global 3.12.0
Phase 3: Identity and SSH
1. SSH Key Generation and Sharing
PowerShell

# [USER] Generate key on Windows
ssh-keygen -t ed25519 -C "your_email@example.com"

# [USER] Mirror key to Debian
mkdir -p ~/.ssh
cp /mnt/c/Users/vsiva/.ssh/id_ed25519* ~/.ssh/

# [USER] Set strict Linux permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
2. Git Global Configuration
Run on both Windows and Debian.

Bash

# [USER] Set identity
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
Phase 4: Project Management and Virtual Environments
The Venv Workflow
While pyenv manages Python versions (e.g., 3.12.0), venv isolates libraries for a specific project. You should create a new virtual environment for every project to prevent dependency conflicts.

Example: Creating a New Project in Debian

Bash

# [USER] Navigate to Linux Home
cd ~

# [USER] Create project directory
mkdir my_data_project && cd my_data_project

# [USER] Create the virtual environment
# This creates a folder named '.venv' containing a local python binary
python -m venv .venv

# [USER] Activate the environment
source .venv/bin/activate

# Your prompt will now show (.venv). Install libraries here:
pip install pandas requests

# [USER] Open in VS Code
code .
