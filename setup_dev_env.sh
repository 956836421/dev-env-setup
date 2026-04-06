#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

INTERACTIVE=true
SELECTED_TOOLS=()
OS_TYPE=""
ARCH=""

declare -A TOOL_INFO=(
    [htop]="Process viewer|htop|htop"
    [tmux]="Terminal multiplexer|tmux|tmux"
    [tree]="Directory tree viewer|tree|tree"
    [ripgrep]="Fast grep (rg)|rg|ripgrep"
    [fzf]="Fuzzy finder|fzf|fzf"
    [bat]="Cat with syntax highlighting|bat|bat"
    [eza]="Modern ls replacement|eza|eza"
    [fd]="Fast find replacement|fd|fd-find"
    [jq]="JSON processor|jq|jq"
    [nvm]="Node.js version manager||nvm"
    [pyenv]="Python version manager||pyenv"
    [go]="Go programming language|go|go"
    [rust]="Rust programming language|rustc|rust"
    [starship]="Cross-shell prompt|starship|starship"
    [zoxide]="Smart cd command|zoxide|zoxide"
)

declare -A TOOL_DESC=()
declare -A TOOL_CHECK=()
declare -A TOOL_PKG=()

init_tool_info() {
    for tool in "${!TOOL_INFO[@]}"; do
        IFS='|' read -r desc check pkg <<< "${TOOL_INFO[$tool]}"
        TOOL_DESC[$tool]="$desc"
        TOOL_CHECK[$tool]="$check"
        TOOL_PKG[$tool]="$pkg"
    done
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        command -v apt-get &> /dev/null && echo "debian" && return
        command -v dnf &> /dev/null && echo "fedora" && return
        command -v yum &> /dev/null && echo "redhat" && return
        echo "linux"
    else
        echo "unknown"
    fi
}

check_command() { command -v "$1" &> /dev/null; }
in_array() { local n="$1"; shift; local i; for i in "$@"; do [[ "$i" == "$n" ]] && return 0; done; return 1; }

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Basic Options:
  -y, --yes      Skip interactive prompts
  -h, --help     Show this help

CLI Tools:    --htop, --tmux, --tree, --ripgrep, --fzf, --bat, --eza, --fd, --jq
Dev Tools:    --nvm, --pyenv, --go, --rust
Other:        --starship, --zoxide

Examples:
  $0                           Interactive mode
  $0 --htop --fzf --starship   Install specific tools
  $0 --nvm --go --rust -y      Install dev tools without prompts
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --htop|--tmux|--tree|--ripgrep|--fzf|--bat|--eza|--fd|--jq|--nvm|--pyenv|--go|--rust|--starship|--zoxide)
                SELECTED_TOOLS+=("${1#--}") ;;
            -y|--yes) INTERACTIVE=false ;;
            -h|--help) show_help; exit 0 ;;
            *) log_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
        shift
    done
}

ask_install() {
    local tool="$1"
    [ "$INTERACTIVE" = false ] && return 1
    in_array "$tool" "${SELECTED_TOOLS[@]}" && return 0
    echo -e -n "${CYAN}  [$tool]${NC} ${TOOL_DESC[$tool]} [y/N]: "
    read -r response
    [[ "$response" =~ ^[yY]([eE][sS])?$ ]] && SELECTED_TOOLS+=("$tool") && return 0
    return 1
}

show_interactive_menu() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Development Environment Setup Script             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}CLI Tools:${NC}"
    for t in htop tmux tree ripgrep fzf bat eza fd jq; do ask_install "$t" || true; done
    echo -e "\n${CYAN}Dev Tools:${NC}"
    for t in nvm pyenv go rust; do ask_install "$t" || true; done
    echo -e "\n${CYAN}Other:${NC}"
    for t in starship zoxide; do ask_install "$t" || true; done
    echo ""
}

install_package() {
    local pkg="$1"
    case $OS_TYPE in
        macos) brew install "$pkg" || true ;;
        debian) sudo apt-get install -y "$pkg" ;;
        redhat|fedora) sudo yum install -y "$pkg" 2>/dev/null || sudo dnf install -y "$pkg" ;;
    esac
}

install_dependencies() {
    log_info "Installing dependencies..."
    local pkgs="git curl wget zsh build-essential"
    [ "$OS_TYPE" = "macos" ] && pkgs="git curl wget zsh"
    [ "$OS_TYPE" = "redhat" ] || [ "$OS_TYPE" = "fedora" ] && pkgs="git curl wget zsh gcc gcc-c++ make"
    
    case $OS_TYPE in
        macos)
            check_command brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            brew install $pkgs || true
            ;;
        debian) sudo apt-get update && sudo apt-get install -y $pkgs ;;
        redhat|fedora) sudo yum install -y $pkgs 2>/dev/null || sudo dnf install -y $pkgs ;;
        *) log_warn "Unknown distro, trying apt..."; sudo apt-get update && sudo apt-get install -y $pkgs 2>/dev/null || true ;;
    esac
}

install_oh_my_zsh() {
    log_info "Installing Oh My Zsh..."
    [ -d "$HOME/.oh-my-zsh" ] && log_warn "Oh My Zsh already installed, skipping..." && return 0
    
    local script="https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh"
    check_command curl && sh -c "$(curl -fsSL $script)" "" --unattended || \
    check_command wget && sh -c "$(wget -qO- $script)" "" --unattended
    
    [ -d "$HOME/.oh-my-zsh" ] && log_info "Oh My Zsh installed successfully"
}

install_zsh_plugins() {
    log_info "Installing Zsh plugins..."
    local dir="$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$dir"
    
    for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
        if [ -d "$dir/$plugin" ]; then
            log_warn "$plugin exists, updating..."
            cd "$dir/$plugin" && git pull || true
        else
            git clone "https://gitee.com/zsh-users/$plugin" "$dir/$plugin" || \
            git clone "https://github.com/zsh-users/$plugin" "$dir/$plugin"
        fi
    done
}

configure_zsh() {
    log_info "Configuring Zsh..."
    local zshrc="$HOME/.zshrc"
    [ -f "$zshrc" ] && cp "$zshrc" "$zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    
    sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="ys"/' "$zshrc" 2>/dev/null || echo 'ZSH_THEME="ys"' >> "$zshrc"
    rm -f "${zshrc}.bak"
    
    grep -q "zsh-syntax-highlighting" "$zshrc" || \
        sed -i.bak 's/^plugins=(/plugins=(zsh-syntax-highlighting zsh-autosuggestions /' "$zshrc" 2>/dev/null || \
        echo 'plugins=(git zsh-syntax-highlighting zsh-autosuggestions)' >> "$zshrc"
    rm -f "${zshrc}.bak"
    
    log_info "Zsh configured with theme 'ys' and plugins"
}

install_miniforge() {
    log_info "Installing Miniforge..."
    check_command conda && log_warn "Conda already installed, skipping..." && return 0
    
    local installer
    case $OS_TYPE in
        macos) [ "$ARCH" = "arm64" ] && installer="Miniforge3-MacOSX-arm64.sh" || installer="Miniforge3-MacOSX-x86_64.sh" ;;
        *) [ "$ARCH" = "aarch64" ] && installer="Miniforge3-Linux-aarch64.sh" || installer="Miniforge3-Linux-x86_64.sh" ;;
    esac
    
    local tmp=$(mktemp -d)
    local tsinghua="https://mirrors.tuna.tsinghua.edu.cn/github-release/conda-forge/miniforge/LatestRelease"
    local github="https://github.com/conda-forge/miniforge/releases/latest/download"
    
    curl -fsSL --connect-timeout 10 "$tsinghua/$installer" -o "$tmp/$installer" || \
    curl -fsSL "$github/$installer" -o "$tmp/$installer" || { log_error "Failed to download Miniforge"; exit 1; }
    
    bash "$tmp/$installer" -b -p "$HOME/miniforge3"
    rm -rf "$tmp"
    
    "$HOME/miniforge3/bin/conda" init zsh bash
    
    local mirror="https://mirrors.tuna.tsinghua.edu.cn/anaconda"
    "$HOME/miniforge3/bin/conda" config --add channels "$mirror/pkgs/free/"
    "$HOME/miniforge3/bin/conda" config --add channels "$mirror/pkgs/main/"
    "$HOME/miniforge3/bin/conda" config --add channels "$mirror/cloud/conda-forge/"
    "$HOME/miniforge3/bin/conda" config --set show_channel_urls yes
    
    log_info "Miniforge installed and initialized"
}

change_default_shell() {
    log_info "Changing default shell to Zsh..."
    [ "$SHELL" = "$(which zsh)" ] && log_info "Default shell is already Zsh" && return 0
    
    grep -q "$(which zsh)" /etc/shells 2>/dev/null || which zsh | sudo tee -a /etc/shells
    chsh -s "$(which zsh)" || log_warn "Failed, please run: chsh -s \$(which zsh)"
}

install_eza() {
    [ "$OS_TYPE" = "macos" ] && { brew install eza || true; return; }
    [ "$OS_TYPE" = "redhat" ] || [ "$OS_TYPE" = "fedora" ] && { sudo dnf install -y eza 2>/dev/null || true; return; }
    
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/eza.gpg 2>/dev/null || true
    echo "deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/eza.list
    sudo apt-get update && sudo apt-get install -y eza || true
}

install_fd() {
    [ "$OS_TYPE" = "macos" ] && { brew install fd || true; return; }
    
    install_package fd-find || true
    [ "$OS_TYPE" = "debian" ] && {
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(which fdfind 2>/dev/null || echo /usr/bin/fdfind)" "$HOME/.local/bin/fd" 2>/dev/null || true
    }
}

add_to_zshrc() {
    local content="$1"
    grep -q "$content" "$HOME/.zshrc" 2>/dev/null || echo -e "\n$content" >> "$HOME/.zshrc"
}

install_nvm() {
    [ -d "$HOME/.nvm" ] && log_warn "nvm already installed" && return
    curl -o- https://ghproxy.com/https://github.com/nvm-sh/nvm/raw/master/install.sh | bash 2>/dev/null || \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    add_to_zshrc 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
    log_info "nvm installed. Run: source ~/.zshrc && nvm install --lts"
}

install_pyenv() {
    [ -d "$HOME/.pyenv" ] && log_warn "pyenv already installed" && return
    curl -L https://ghproxy.com/https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash 2>/dev/null || \
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
    add_to_zshrc 'export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"'
    log_info "pyenv installed. Run: source ~/.zshrc && pyenv install 3.12"
}

install_go() {
    check_command go && log_warn "Go already installed" && return
    local ver="1.22.1" file
    [ "$OS_TYPE" = "macos" ] && [ "$ARCH" = "arm64" ] && file="go${ver}.darwin-arm64.tar.gz" || file="go${ver}.darwin-amd64.tar.gz"
    [ "$OS_TYPE" != "macos" ] && [ "$ARCH" = "aarch64" ] && file="go${ver}.linux-arm64.tar.gz" || file="go${ver}.linux-amd64.tar.gz"
    
    local tmp=$(mktemp -d)
    curl -fsSL "https://golang.google.cn/dl/$file" -o "$tmp/$file"
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "$tmp/$file"
    rm -rf "$tmp"
    add_to_zshrc 'export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin'
    log_info "Go installed"
}

install_rust() {
    check_command rustc && log_warn "Rust already installed" && return
    export RUSTUP_DIST_SERVER="https://rsproxy.cn" RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
    curl -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y
    add_to_zshrc 'export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
. "$HOME/.cargo/env"'
    log_info "Rust installed"
}

install_starship() {
    check_command starship && log_warn "Starship already installed" && return
    local file
    [ "$OS_TYPE" = "macos" ] && [ "$ARCH" = "arm64" ] && file="starship-aarch64-apple-darwin.tar.gz" || file="starship-x86_64-apple-darwin.tar.gz"
    [ "$OS_TYPE" != "macos" ] && [ "$ARCH" = "aarch64" ] && file="starship-aarch64-unknown-linux-gnu.tar.gz" || file="starship-x86_64-unknown-linux-gnu.tar.gz"
    
    local tmp=$(mktemp -d)
    curl -fsSL "https://ghproxy.com/https://github.com/starship/starship/releases/latest/download/$file" -o "$tmp/$file" || \
    curl -fsSL "https://github.com/starship/starship/releases/latest/download/$file" -o "$tmp/$file"
    
    tar -xzf "$tmp/$file" -C "$tmp"
    mkdir -p "$HOME/.local/bin"
    mv "$tmp/starship" "$HOME/.local/bin/" && chmod +x "$HOME/.local/bin/starship"
    rm -rf "$tmp"
    
    add_to_zshrc 'export PATH="$HOME/.local/bin:$PATH"
eval "$(starship init zsh)"'
    log_info "Starship installed"
}

install_zoxide() {
    check_command zoxide && log_warn "zoxide already installed" && return
    curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    add_to_zshrc 'eval "$(zoxide init zsh)"'
    log_info "zoxide installed. Use 'z' for smart cd"
}

install_tool() {
    local tool="$1"
    local check="${TOOL_CHECK[$tool]}"
    local pkg="${TOOL_PKG[$tool]}"
    
    [ -n "$check" ] && check_command "$check" && log_warn "$tool already installed, skipping..." && return
    
    log_info "Installing $tool..."
    case $tool in
        htop|tmux|tree|jq|ripgrep|fzf|bat) install_package "$pkg" ;;
        eza) install_eza ;;
        fd) install_fd ;;
        nvm) install_nvm ;;
        pyenv) install_pyenv ;;
        go) install_go ;;
        rust) install_rust ;;
        starship) install_starship ;;
        zoxide) install_zoxide ;;
    esac
}

install_selected_tools() {
    [ ${#SELECTED_TOOLS[@]} -eq 0 ] && return
    log_info "Installing selected tools: ${SELECTED_TOOLS[*]}"
    for tool in "${SELECTED_TOOLS[@]}"; do install_tool "$tool"; done
}

main() {
    init_tool_info
    parse_args "$@"
    
    OS_TYPE=$(detect_os)
    ARCH=$(uname -m)
    
    [ "$INTERACTIVE" = true ] && [ ${#SELECTED_TOOLS[@]} -eq 0 ] && show_interactive_menu
    
    log_info "Starting installation..."
    log_info "OS: $OS_TYPE, Arch: $ARCH"
    [ "$OS_TYPE" = "unknown" ] && log_error "Unsupported OS" && exit 1
    
    install_dependencies
    install_oh_my_zsh
    install_zsh_plugins
    configure_zsh
    install_miniforge
    change_default_shell
    install_selected_tools
    
    echo ""
    log_info "Installation completed!"
    log_info "Run 'exec zsh' to start Zsh"
}

main "$@"
