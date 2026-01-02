# Health Check Script for Windows/PowerShell Environment
# Verifies all tools from shell_setup are properly installed

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  Shell Setup Health Check (Windows)" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$pass = 0
$fail = 0

function Check-Command {
    param($Name, $Command)
    
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if ($cmd) {
        try {
            $version = & $Command --version 2>$null | Select-Object -First 1
            Write-Host "[OK] $Name`: $version" -ForegroundColor Green
        } catch {
            Write-Host "[OK] $Name`: installed" -ForegroundColor Green
        }
        $script:pass++
    } else {
        Write-Host "[FAIL] $Name`: not found" -ForegroundColor Red
        $script:fail++
    }
}

function Check-Module {
    param($Name)
    
    if (Get-Module -ListAvailable -Name $Name) {
        Write-Host "[OK] Module $Name`: installed" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "[FAIL] Module $Name`: not found" -ForegroundColor Red
        $script:fail++
    }
}

function Check-File {
    param($Name, $Path)
    
    $expandedPath = [Environment]::ExpandEnvironmentVariables($Path)
    if (Test-Path $expandedPath) {
        Write-Host "[OK] $Name`: exists" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "[FAIL] $Name`: not found at $Path" -ForegroundColor Red
        $script:fail++
    }
}

Write-Host "--- Core Tools ---" -ForegroundColor Yellow
Check-Command "Git" "git"
Check-Command "Python" "python"
Check-Command "Pip" "pip"

Write-Host ""
Write-Host "--- Package Manager ---" -ForegroundColor Yellow
Check-Command "Scoop" "scoop"

Write-Host ""
Write-Host "--- Shell Enhancements ---" -ForegroundColor Yellow
Check-Command "Starship" "starship"
Check-Command "fzf" "fzf"

Write-Host ""
Write-Host "--- PowerShell Modules ---" -ForegroundColor Yellow
Check-Module "PSReadLine"
Check-Module "Terminal-Icons"
Check-Module "z"
Check-Module "PSFzf"
Check-Module "posh-git"

Write-Host ""
Write-Host "--- VS Code ---" -ForegroundColor Yellow
Check-Command "VS Code (code)" "code"

Write-Host ""
Write-Host "--- Build Tools ---" -ForegroundColor Yellow
Check-Command "CMake" "cmake"
Check-Command "Ninja" "ninja"
Check-Command "Clang" "clang"
Check-Command "GCC" "gcc"
Check-Command "Make" "make"
Check-Command "SCons" "scons"
Check-Command "pre-commit" "pre-commit"

Write-Host ""
Write-Host "--- Document Conversion ---" -ForegroundColor Yellow
Check-Command "Pandoc" "pandoc"
Check-Command "MiKTeX (pdflatex)" "pdflatex"
Check-Command "Inkscape" "inkscape"

Write-Host ""
Write-Host "--- AI Tools ---" -ForegroundColor Yellow
Check-Command "Ollama" "ollama"
Check-Command "Opencode" "opencode"

# Check Ollama server status
try {
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 2 -ErrorAction SilentlyContinue
    Write-Host "[OK] Ollama server: running" -ForegroundColor Green
    $pass++
    
    # Check if qwen3-coder model is available
    $models = ollama list 2>$null
    if ($models -match "qwen3-coder") {
        Write-Host "[OK] Ollama model: qwen3-coder found" -ForegroundColor Green
        $pass++
    } else {
        Write-Host "[WARN] Ollama model: qwen3-coder not found (run: ollama pull qwen3-coder:30b)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[WARN] Ollama server: not running (run: ollama serve)" -ForegroundColor Yellow
}

# Check Opencode config
Check-File "Opencode config" "$HOME\.config\opencode\opencode.json"

Write-Host ""
Write-Host "--- Python Packages ---" -ForegroundColor Yellow
$pypandoc = pip show pypandoc 2>$null
if ($pypandoc) {
    $version = ($pypandoc | Select-String "Version:").ToString().Split(":")[1].Trim()
    Write-Host "[OK] pypandoc: $version" -ForegroundColor Green
    $pass++
} else {
    Write-Host "[FAIL] pypandoc: not installed" -ForegroundColor Red
    $fail++
}

$pyyaml = pip show pyyaml 2>$null
if ($pyyaml) {
    $version = ($pyyaml | Select-String "Version:").ToString().Split(":")[1].Trim()
    Write-Host "[OK] pyyaml: $version" -ForegroundColor Green
    $pass++
} else {
    Write-Host "[FAIL] pyyaml: not installed" -ForegroundColor Red
    $fail++
}

Write-Host ""
Write-Host "--- Config Files ---" -ForegroundColor Yellow
Check-File "PowerShell Profile" $PROFILE
Check-File "Starship config" "$HOME\.config\starship.toml"

Write-Host ""
Write-Host "--- WSL ---" -ForegroundColor Yellow
$wslList = wsl --list --quiet 2>$null
if ($wslList) {
    Write-Host "[OK] WSL installed with: $($wslList -join ', ')" -ForegroundColor Green
    $pass++
} else {
    Write-Host "[FAIL] WSL not installed or no distributions" -ForegroundColor Red
    $fail++
}

Write-Host ""
Write-Host "--- SSH Setup ---" -ForegroundColor Yellow
if (Test-Path "$HOME\.ssh\id_ed25519") {
    Write-Host "[OK] SSH key exists" -ForegroundColor Green
    $pass++
} else {
    Write-Host "[WARN] SSH key not found (optional)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Results: $pass passed, $fail failed" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

if ($fail -eq 0) {
    Write-Host "All checks passed!" -ForegroundColor Green
} else {
    Write-Host "Some checks failed. See README for installation instructions." -ForegroundColor Yellow
}
