# Modern Windows + WSL2 Development Environment Setup

> **Purpose**: Configure a professional dual-environment setup for Python development on Windows and Linux (WSL2).
>
> **Target Audience**: Developers who need flexibility between Windows-native and Linux-based workflows.
>
> **Estimated Time**: 45-60 minutes (including restart)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Part 1: Windows Host Configuration](#part-1-windows-host-configuration)
3. [Part 2: WSL2 & Debian Setup](#part-2-wsl2--debian-setup)
4. [Part 3: Python Version Management](#part-3-python-version-management)
5. [Part 4: Git & SSH Configuration](#part-4-git--ssh-configuration)
6. [Part 5: Standard Development Workflows](#part-5-standard-development-workflows)
7. [VS Code Integration Tips](#vs-code-integration-tips)
8. [Troubleshooting](#troubleshooting)
9. [Maintenance & Updates](#maintenance--updates)
10. [Next Steps](#next-steps)
11. [Additional Resources](#additional-resources)

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
scoop install vscode starship CascadiaCode-NF-Mono python
```

**Verification**:

```powershell
scoop list
# Should show git, vscode, starship, etc.
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
cp /mnt/c/Users/vsiva/.ssh/id_ed25519* ~/.ssh/

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

## Part 5: Standard Development Workflows

### When to Use Each Environment

| Use Windows (PowerShell) | Use Linux (WSL2/Debian) |
|--------------------------|-------------------------|
| Windows-specific development | Backend/server development |
| .NET or Windows GUI apps | Data science/ML workflows |
| Native Windows scripting | Docker containers |
| Testing on Windows | Shell scripting (bash) |

---

### Workflow A: Linux Development (Recommended for most Python work)

**Environment**: Debian (Bash)

```bash
# 1. Navigate to home directory
cd ~

# 2. Create project folder
mkdir my_project && cd my_project

# 3. Initialize git repository (optional but recommended)
git init

# 4. Create virtual environment
python -m venv .venv

# 5. Activate environment
source .venv/bin/activate

# Your prompt should now show (.venv) prefix

# 6. Upgrade pip and install packages
pip install --upgrade pip
pip install requests pandas numpy

# 7. Create requirements file for reproducibility
pip freeze > requirements.txt

# 8. Open in VS Code
code .
```

**Deactivate when done**:

```bash
deactivate
```

---

### Workflow B: Windows Development

**Environment**: PowerShell 7

```powershell
# 1. Navigate to your projects directory
cd ~\Documents
mkdir my_win_project
cd my_win_project

# 2. Initialize git repository (optional)
git init

# 3. Create virtual environment
python -m venv .venv

# 4. Activate environment
.\.venv\Scripts\Activate.ps1

# Your prompt should now show (.venv) prefix

# 5. Upgrade pip and install packages
pip install --upgrade pip
pip install requests pandas

# 6. Create requirements file
pip freeze > requirements.txt

# 7. Open in VS Code
code .
```

**Deactivate when done**:

```powershell
deactivate
```

---

## VS Code Integration Tips

### Recommended Extensions

- **Python** (Microsoft) - IntelliSense, debugging, linting
- **Pylance** (Microsoft) - Fast Python language server
- **WSL** (Microsoft) - Seamless WSL integration
- **GitLens** - Enhanced Git visualization

### Configure Python Interpreter

1. Open Command Palette (`Ctrl+Shift+P`)
2. Type "Python: Select Interpreter"
3. Choose the interpreter from your `.venv` folder

---

## Troubleshooting

### Issue: `scoop install` fails with "Couldn't find manifest"

**Solution**: Ensure Git was installed first: `scoop install git`

### Issue: WSL2 won't start after installation

**Solution**: Enable virtualization in BIOS and run: `wsl --set-default-version 2`

### Issue: SSH key permissions error in WSL

**Solution**: Re-run the chmod commands exactly as shown in section 4.2

### Issue: Python command not found after pyenv install

**Solution**: Reload shell with `source ~/.bashrc` or restart terminal

### Issue: VS Code can't find Python interpreter

**Solution**: Make sure virtual environment is activated, then reload VS Code window

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
pyenv install 3.12.x  # Replace with desired version
pyenv global 3.12.x
```

---

## Next Steps

1. **Test Your Setup**: Create a test project using both workflows
2. **Backup SSH Keys**: Save your `~/.ssh` folder securely
3. **Explore Advanced Tools**: Consider Docker Desktop with WSL2 backend
4. **Configure VS Code**: Install extensions and customize settings
5. **Learn Git Workflows**: Familiarize yourself with branches, commits, and pull requests

---

## Additional Resources

- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [Scoop Package Manager](https://scoop.sh/)
- [WSL Documentation](https://docs.microsoft.com/windows/wsl/)
- [pyenv Documentation](https://github.com/pyenv/pyenv)
- [Starship Prompt](https://starship.rs/)
- [Git Best Practices](https://git-scm.com/book/en/v2)

---

## License

This documentation is provided as-is for educational purposes. Feel free to adapt it to your needs.

## Contributing

If you find errors or have suggestions for improvement, please submit feedback or pull requests.

---

**Last Updated**: December 2025  
**Maintainer**: Your Name  
**Version**: 1.0
