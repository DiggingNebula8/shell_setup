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
scoop install starship CascadiaCode-NF-Mono python cmake ninja llvm

# Install pre-commit (via pip, as it's a Python tool)
pip install pre-commit
```

**Verification**:

```powershell
scoop list
# Should show git, starship, python, cmake, ninja, llvm, etc.

pre-commit --version
# Should show pre-commit version
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

### 1.5 Install Visual Studio & C++ Build Tools

**Why**: Required for building native C/C++ projects (e.g., Aseprite, game engines, Python extensions with C code).

**Environment**: Windows  
**Privilege**: Administrator

#### Option A: Visual Studio Community (Recommended)

1. Download from [visualstudio.microsoft.com](https://visualstudio.microsoft.com/)
2. Run the installer and select **"Desktop development with C++"** workload
3. Ensure these components are selected:
   - MSVC v143 (or latest) - C++ compiler
   - Windows 11 SDK (or Windows 10 SDK)
   - C++ CMake tools for Windows

**Current Version**: Visual Studio 2026 (v18.x) or Visual Studio 2022 (v17.x)

#### Option B: Build Tools Only (Lighter, ~4GB)

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

#### Using MSVC in PowerShell

MSVC tools (`cl`, `link`, `nmake`) are **not** in PATH by default. You must load the Visual Studio Developer environment first.

**Option 1: Use Developer PowerShell** (from Start Menu)
- Search for "Developer PowerShell for VS 2026" (or 2022)

**Option 2: Load VS environment on-demand** (add to your profile)

```powershell
function Enter-VSEnv {
    # Find VS installation path
    $vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -property installationPath
    & "$vsPath\Common7\Tools\Launch-VsDevShell.ps1" -Arch amd64 -SkipAutomaticLocation
}
```

Then run `Enter-VSEnv` before building C++ projects.

**Verification**:

```powershell
Enter-VSEnv
where.exe cl
# Should show path to cl.exe
```

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
# Add VS Code to PATH (standard installer location)
echo 'export PATH="$PATH:/mnt/c/Users/'"$USER"'/AppData/Local/Programs/Microsoft VS Code/bin"' >> ~/.bashrc

# Reload configuration
source ~/.bashrc
```

> **Note**: If you installed VS Code differently, find the correct path with:
> ```powershell
> # In PowerShell on Windows
> (Get-Command code).Source
> ```

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

Copy the profile from this repository to your PowerShell profile location:

```powershell
# Find your profile location
echo $PROFILE

# Typical location: ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

📄 **See the full profile:** [Microsoft.PowerShell_profile.ps1](Microsoft.PowerShell_profile.ps1)

This profile includes:
- Starship prompt initialization
- Module imports (Terminal-Icons, z, PSFzf, posh-git)
- PSReadLine configuration with history-based predictions
- Navigation aliases (`..`, `...`, `mkcd`)
- Git shortcuts (`gs`, `ga`, `gc`, `gp`, `glog`)
- Python helpers (`py`, `va`, `vd`)
- CMake/Ninja shortcuts (`cmk`, `cmkd`, `cmkr`, `cmkb`, `nb`)
- Custom functions (`new-project`, `which`, `disk-usage`)

Apply changes: Close and reopen PowerShell

---

### 6.2 Bash Enhancements (WSL)

#### Install Modern CLI Tools

**Environment**: Debian (Bash)  
**Privilege**: User (with sudo)

```bash
# Install build tools
sudo apt install -y cmake ninja-build clang

# Install pre-commit (via pip)
pip install pre-commit

# Install modern replacements for classic tools
sudo apt install -y \
  fzf \           # Fuzzy finder
  bat \           # Better cat
  ripgrep \       # Better grep
  fd-find \       # Better find
  tldr \          # Simple man pages
  htop \          # Better top
  ncdu            # Disk usage

# Install eza (modern ls replacement, successor to exa)
# Note: eza may need to be installed from a different source on Debian
# See: https://github.com/eza-community/eza
# Fallback: sudo apt install exa (if available)

# Install autojump (smart directory navigation)
sudo apt install -y autojump
```

#### Enhanced Bash Configuration

Copy the `.bashrc` from this repository to your home directory:

```bash
# Backup existing .bashrc
cp ~/.bashrc ~/.bashrc.backup

# Copy from repo (adjust path as needed)
cp /path/to/repo/.bashrc ~/.bashrc

# Reload
source ~/.bashrc
```

📄 **See the full configuration:** [.bashrc](.bashrc)

This configuration includes:
- **History**: Extended history (10,000 entries), duplicate removal
- **Shell options**: `globstar`, `cdspell`, `checkwinsize`
- **Tool integrations**: pyenv, Starship, fastfetch
- **Modern CLI aliases**: eza/exa (ls), bat (cat), ripgrep (grep), fd (find)
- **Navigation**: `..`, `...`, `mkcd`, autojump
- **Git shortcuts**: `gs`, `ga`, `gc`, `gp`, `glog`, `gstash`
- **Python**: `py`, `va`, `vd`, `pipr`, `pipf`
- **CMake/Ninja**: `cmk`, `cmkd`, `cmkr`, `cmkb`, `cmkclean`, `nb`
- **Functions**: `extract()`, `new-project()`, `myip()`, `weather()`
- **FZF**: Dracula-themed fuzzy finder with ripgrep integration
- **Colored man pages**

---

### 6.3 Starship Custom Configuration

Create a custom Starship theme that works in both environments. Create separately or create a symlink.

**Location**: `~/.config/starship.toml` (Windows and Linux)

```bash
# Linux: Create config directory and copy
mkdir -p ~/.config
cp /path/to/repo/starship.toml ~/.config/starship.toml

# Windows PowerShell: Create config directory and copy
mkdir -Force ~/.config
copy starship.toml ~/.config/starship.toml
```

📄 **See the full configuration:** [starship.toml](starship.toml)

This Starship configuration includes:
- **Custom prompt format**: Clean two-line layout with git and language info
- **Git integration**: Branch display with status indicators (staged, modified, untracked)
- **Language detection**: Python, Node.js, Rust, Go version display
- **SSH-aware**: Only shows username/hostname when connected via SSH
- **Performance**: 500ms command timeout for fast prompts
- **Command duration**: Shows elapsed time for long-running commands (>2s)

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
