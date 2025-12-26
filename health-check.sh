#!/bin/bash
# Health Check Script for WSL/Linux Environment
# Verifies all tools from shell_setup are properly installed

echo "=================================="
echo "  Shell Setup Health Check (Linux)"
echo "=================================="
echo ""

PASS=0
FAIL=0

check() {
    local name="$1"
    local cmd="$2"
    
    if command -v "$cmd" &> /dev/null; then
        version=$($cmd --version 2>/dev/null | head -n1 || echo "installed")
        echo "[OK] $name: $version"
        ((PASS++))
    else
        echo "[FAIL] $name: not found"
        ((FAIL++))
    fi
}

check_file() {
    local name="$1"
    local file="$2"
    
    if [ -f "$file" ]; then
        echo "[OK] $name: exists"
        ((PASS++))
    else
        echo "[FAIL] $name: not found at $file"
        ((FAIL++))
    fi
}

echo "--- Core Tools ---"
check "Git" "git"
check "Python" "python3"
check "Pip" "pip3"
check "Curl" "curl"

echo ""
echo "--- Shell Enhancements ---"
check "Starship" "starship"
check "fzf" "fzf"

echo ""
echo "--- Modern CLI Tools ---"
check "bat (better cat)" "bat"
check "eza/exa (better ls)" "eza" || check "exa (better ls)" "exa"
check "ripgrep (better grep)" "rg"
check "fd-find (better find)" "fdfind"
check "htop" "htop"
check "ncdu" "ncdu"

echo ""
echo "--- Python Environment ---"
check "pyenv" "pyenv"

echo ""
echo "--- VS Code ---"
check "VS Code (code)" "code"

echo ""
echo "--- Config Files ---"
check_file "~/.bashrc" "$HOME/.bashrc"
check_file "Starship config" "$HOME/.config/starship.toml"

echo ""
echo "--- SSH Setup ---"
if [ -f "$HOME/.ssh/id_ed25519" ]; then
    echo "[OK] SSH key exists"
    ((PASS++))
else
    echo "[WARN] SSH key not found (optional)"
fi

echo ""
echo "=================================="
echo "Results: $PASS passed, $FAIL failed"
echo "=================================="

if [ $FAIL -eq 0 ]; then
    echo "All checks passed!"
    exit 0
else
    echo "Some checks failed. See README for installation instructions."
    exit 1
fi
