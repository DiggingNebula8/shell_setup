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

# Prefer eza/exa if available, otherwise fallback to ls --color
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lah --icons --group-directories-first'
    alias la='eza -a --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
elif command -v exa &> /dev/null; then
    alias ls='exa --icons --group-directories-first'
    alias ll='exa -lah --icons --group-directories-first'
    alias la='exa -a --icons --group-directories-first'
    alias lt='exa --tree --level=2 --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah'
    alias la='ls -a'
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
alias jbs='jobs -l'  # 'j' is reserved for autojump
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
fdir() { find . -type d -iname "*$1*"; }  # renamed from fd() to avoid conflict with fd-find

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
    # Empty location = auto-detect via IP geolocation
    curl -s "wttr.in/${1}?format=3"
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
    echo "  ..      - Go up one directory"
    echo "  ...     - Go up two directories"
    echo "  ....    - Go up three directories"
    echo "  mkcd    - Create and enter directory"
    echo "  j       - Jump to directory (autojump)"
    
    echo -e "\n\e[33m=== File Listing ===\e[0m"
    echo "  ls      - List with icons (eza/exa)"
    echo "  ll      - Long list with details"
    echo "  la      - List all including hidden"
    echo "  lt      - Tree view (2 levels)"
    
    echo -e "\n\e[33m=== Git ===\e[0m"
    echo "  gs      - git status"
    echo "  ga      - git add"
    echo "  gc      - git commit -m"
    echo "  gp      - git push"
    echo "  gpl     - git pull"
    echo "  gd      - git diff"
    echo "  gco     - git checkout"
    echo "  gb      - git branch"
    echo "  glog    - Pretty git log"
    echo "  gstash  - git stash"
    echo "  gpop    - git stash pop"
    echo "  gclean  - git clean -fd"
    
    echo -e "\n\e[33m=== Python ===\e[0m"
    echo "  py      - python3"
    echo "  ipy     - ipython"
    echo "  va      - Activate .venv"
    echo "  vd      - Deactivate venv"
    echo "  pipr    - pip install -r requirements.txt"
    echo "  pipf    - pip freeze > requirements.txt"
    
    echo -e "\n\e[33m=== Search & Find ===\e[0m"
    echo "  ff      - Find files by name"
    echo "  fdir    - Find directories by name"
    echo "  fd      - fd-find (better find)"
    echo "  grep    - ripgrep (better grep)"
    
    echo -e "\n\e[33m=== Utilities ===\e[0m"
    echo "  cat     - bat (better cat)"
    echo "  c       - clear"
    echo "  h       - history"
    echo "  jbs     - jobs -l (list jobs)"
    echo "  path    - Show PATH entries"
    echo "  extract - Extract any archive"
    echo "  myip    - Get public IP"
    echo "  weather - Get weather forecast"
    echo "  update  - apt update && upgrade"
    
    echo -e "\n\e[33m=== Config ===\e[0m"
    echo "  bashrc  - Edit ~/.bashrc"
    echo "  reload  - Reload ~/.bashrc"
    echo ""
}
