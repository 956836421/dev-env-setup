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

CLI_TOOLS_LIST="htop tmux tree ripgrep fzf bat eza fd jq"
DEV_TOOLS_LIST="nvm pyenv go rust"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Basic Options:"
    echo "  -y, --yes      Skip interactive prompts (use with tool options)"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "CLI Tools:"
    echo "  --htop         Install htop (process viewer)"
    echo "  --tmux         Install tmux (terminal multiplexer)"
    echo "  --tree         Install tree (directory viewer)"
    echo "  --ripgrep      Install ripgrep (fast grep)"
    echo "  --fzf          Install fzf (fuzzy finder)"
    echo "  --bat          Install bat (cat with syntax highlighting)"
    echo "  --eza          Install eza (modern ls)"
    echo "  --fd           Install fd (fast find)"
    echo "  --jq           Install jq (JSON processor)"
    echo ""
    echo "Dev Tools:"
    echo "  --nvm          Install nvm (Node.js version manager)"
    echo "  --pyenv        Install pyenv (Python version manager)"
    echo "  --go           Install Go"
    echo "  --rust         Install Rust"
    echo ""
    echo "Other Tools:"
    echo "  --starship     Install Starship prompt"
    echo "  --zoxide       Install zoxide (smart cd)"
    echo ""
    echo "Examples:"
    echo "  $0                           Interactive mode"
    echo "  $0 --htop --fzf --starship   Install specific tools"
    echo "  $0 --nvm --go --rust -y      Install dev tools without prompts"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --htop|--tmux|--tree|--ripgrep|--fzf|--bat|--eza|--fd|--jq|--nvm|--pyenv|--go|--rust|--starship|--zoxide)
                SELECTED_TOOLS+=("${1#--}")
                shift
                ;;
            -y|--yes)
                INTERACTIVE=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "debian"
        elif command -v yum &> /dev/null; then
            echo "redhat"
        elif command -v dnf &> /dev/null; then
            echo "fedora"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

in_array() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

ask_install() {
    local tool="$1"
    local desc="$2"
    
    if [ "$INTERACTIVE" = false ]; then
        return 1
    fi
    
    if in_array "$tool" "${SELECTED_TOOLS[@]}"; then
        return 0
    fi
    
    echo -e -n "${CYAN}  [$tool]${NC} $desc [y/N]: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            SELECTED_TOOLS+=("$tool")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

show_interactive_menu() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Development Environment Setup Script             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Select optional tools to install:${NC}"
    echo ""
    echo -e "${CYAN}CLI Tools:${NC}"
    ask_install "htop" "Process viewer" || true
    ask_install "tmux" "Terminal multiplexer" || true
    ask_install "tree" "Directory tree viewer" || true
    ask_install "ripgrep" "Fast grep (rg)" || true
    ask_install "fzf" "Fuzzy finder" || true
    ask_install "bat" "Cat with syntax highlighting" || true
    ask_install "eza" "Modern ls replacement" || true
    ask_install "fd" "Fast find replacement" || true
    ask_install "jq" "JSON processor" || true
    echo ""
    echo -e "${CYAN}Dev Tools:${NC}"
    ask_install "nvm" "Node.js version manager" || true
    ask_install "pyenv" "Python version manager" || true
    ask_install "go" "Go programming language" || true
    ask_install "rust" "Rust programming language" || true
    echo ""
    echo -e "${CYAN}Other:${NC}"
    ask_install "starship" "Cross-shell prompt" || true
    ask_install "zoxide" "Smart cd command" || true
    echo ""
}

install_dependencies() {
    local os_type=$1
    log_info "Installing dependencies..."
    
    case $os_type in
        macos)
            if ! check_command brew; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install git curl wget zsh || true
            ;;
        debian)
            sudo apt-get update
            sudo apt-get install -y git curl wget zsh build-essential
            ;;
        redhat|fedora)
            sudo yum install -y git curl wget zsh gcc gcc-c++ make || sudo dnf install -y git curl wget zsh gcc gcc-c++ make
            ;;
        *)
            log_warn "Unknown Linux distribution, trying common package manager..."
            sudo apt-get update 2>/dev/null || sudo yum update 2>/dev/null || true
            sudo apt-get install -y git curl wget zsh build-essential 2>/dev/null || sudo yum install -y git curl wget zsh gcc gcc-c++ make 2>/dev/null || true
            ;;
    esac
}

install_oh_my_zsh() {
    log_info "Installing Oh My Zsh..."
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_warn "Oh My Zsh already installed, skipping..."
        return 0
    fi
    
    local install_script="https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh"
    
    if check_command curl; then
        sh -c "$(curl -fsSL $install_script)" "" --unattended
    elif check_command wget; then
        sh -c "$(wget -qO- $install_script)" "" --unattended
    else
        log_error "curl or wget required"
        exit 1
    fi
    
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_error "Oh My Zsh installation failed"
        exit 1
    fi
    
    log_info "Oh My Zsh installed successfully"
}

install_zsh_plugins() {
    log_info "Installing Zsh plugins..."
    
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    local gitee_base="https://gitee.com/zsh-users"
    
    mkdir -p "$plugins_dir"
    
    if [ -d "$plugins_dir/zsh-syntax-highlighting" ]; then
        log_warn "zsh-syntax-highlighting already exists, updating..."
        cd "$plugins_dir/zsh-syntax-highlighting" && git pull || true
    else
        log_info "Cloning zsh-syntax-highlighting from Gitee..."
        git clone "$gitee_base/zsh-syntax-highlighting" "$plugins_dir/zsh-syntax-highlighting" || {
            log_warn "Gitee clone failed, trying GitHub..."
            git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"
        }
    fi
    
    if [ -d "$plugins_dir/zsh-autosuggestions" ]; then
        log_warn "zsh-autosuggestions already exists, updating..."
        cd "$plugins_dir/zsh-autosuggestions" && git pull || true
    else
        log_info "Cloning zsh-autosuggestions from Gitee..."
        git clone "$gitee_base/zsh-autosuggestions" "$plugins_dir/zsh-autosuggestions" || {
            log_warn "Gitee clone failed, trying GitHub..."
            git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
        }
    fi
    
    log_info "Zsh plugins installed successfully"
}

configure_zsh() {
    log_info "Configuring Zsh..."
    
    local zshrc="$HOME/.zshrc"
    local zshrc_backup="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$zshrc" ]; then
        cp "$zshrc" "$zshrc_backup"
        log_info "Backup created: $zshrc_backup"
    fi
    
    if grep -q "^ZSH_THEME=" "$zshrc" 2>/dev/null; then
        sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="ys"/' "$zshrc"
        rm -f "${zshrc}.bak"
    else
        echo 'ZSH_THEME="ys"' >> "$zshrc"
    fi
    
    if grep -q "^plugins=" "$zshrc" 2>/dev/null; then
        if ! grep -q "zsh-syntax-highlighting" "$zshrc"; then
            sed -i.bak 's/^plugins=(/plugins=(zsh-syntax-highlighting zsh-autosuggestions /' "$zshrc"
            rm -f "${zshrc}.bak"
        fi
    else
        echo 'plugins=(git zsh-syntax-highlighting zsh-autosuggestions)' >> "$zshrc"
    fi
    
    log_info "Zsh configured with theme 'ys' and plugins"
}

install_miniforge() {
    log_info "Installing Miniforge..."
    
    if check_command conda; then
        log_warn "Conda already installed, skipping..."
        return 0
    fi
    
    local os_type=$(detect_os)
    local arch=$(uname -m)
    local installer=""
    local tsinghua_url="https://mirrors.tuna.tsinghua.edu.cn/github-release/conda-forge/miniforge/LatestRelease"
    local github_url="https://github.com/conda-forge/miniforge/releases/latest/download"
    
    case $os_type in
        macos)
            if [ "$arch" = "arm64" ]; then
                installer="Miniforge3-MacOSX-arm64.sh"
            else
                installer="Miniforge3-MacOSX-x86_64.sh"
            fi
            ;;
        *)
            if [ "$arch" = "aarch64" ]; then
                installer="Miniforge3-Linux-aarch64.sh"
            elif [ "$arch" = "x86_64" ]; then
                installer="Miniforge3-Linux-x86_64.sh"
            else
                log_error "Unsupported architecture: $arch"
                exit 1
            fi
            ;;
    esac
    
    local tmp_dir=$(mktemp -d)
    local installer_path="$tmp_dir/$installer"
    
    log_info "Downloading Miniforge: $installer"
    
    if curl -fsSL --connect-timeout 10 "$tsinghua_url/$installer" -o "$installer_path"; then
        log_info "Downloaded from Tsinghua mirror"
    else
        log_warn "Tsinghua mirror failed, trying GitHub..."
        if ! curl -fsSL "$github_url/$installer" -o "$installer_path"; then
            log_error "Failed to download Miniforge"
            exit 1
        fi
    fi
    
    log_info "Installing Miniforge..."
    bash "$installer_path" -b -p "$HOME/miniforge3"
    
    rm -rf "$tmp_dir"
    
    log_info "Initializing Miniforge..."
    "$HOME/miniforge3/bin/conda" init zsh bash
    
    log_info "Configuring conda to use Tsinghua mirror..."
    "$HOME/miniforge3/bin/conda" config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
    "$HOME/miniforge3/bin/conda" config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
    "$HOME/miniforge3/bin/conda" config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
    "$HOME/miniforge3/bin/conda" config --set show_channel_urls yes
    
    log_info "Miniforge installed and initialized successfully"
}

change_default_shell() {
    log_info "Changing default shell to Zsh..."
    
    if [ "$SHELL" = "$(which zsh)" ]; then
        log_info "Default shell is already Zsh"
        return 0
    fi
    
    if ! grep -q "$(which zsh)" /etc/shells 2>/dev/null; then
        which zsh | sudo tee -a /etc/shells
    fi
    
    chsh -s "$(which zsh)" || {
        log_warn "Failed to change default shell automatically, please run: chsh -s \$(which zsh)"
    }
}

install_tool() {
    local tool="$1"
    local os_type=$(detect_os)
    
    case $tool in
        htop|tmux|tree|jq)
            case $os_type in
                macos) brew install $tool || true ;;
                debian) sudo apt-get install -y $tool ;;
                redhat|fedora) sudo yum install -y $tool || sudo dnf install -y $tool ;;
            esac
            ;;
        ripgrep)
            case $os_type in
                macos) brew install ripgrep || true ;;
                debian) sudo apt-get install -y ripgrep ;;
                redhat|fedora) sudo yum install -y ripgrep || sudo dnf install -y ripgrep ;;
            esac
            ;;
        fzf)
            case $os_type in
                macos) brew install fzf || true ;;
                debian) sudo apt-get install -y fzf ;;
                redhat|fedora) sudo yum install -y fzf || sudo dnf install -y fzf ;;
            esac
            ;;
        bat)
            case $os_type in
                macos) brew install bat || true ;;
                debian) sudo apt-get install -y bat ;;
                redhat|fedora) sudo yum install -y bat || sudo dnf install -y bat ;;
            esac
            ;;
        eza)
            case $os_type in
                macos) brew install eza || true ;;
                debian)
                    if ! check_command eza; then
                        sudo mkdir -p /etc/apt/keyrings
                        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/eza.gpg 2>/dev/null || true
                        echo "deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/eza.list
                        sudo apt-get update && sudo apt-get install -y eza || true
                    fi
                    ;;
                redhat|fedora) sudo dnf install -y eza 2>/dev/null || true ;;
            esac
            ;;
        fd)
            case $os_type in
                macos) brew install fd || true ;;
                debian)
                    sudo apt-get install -y fd-find || true
                    mkdir -p "$HOME/.local/bin"
                    ln -sf "$(which fdfind 2>/dev/null || echo /usr/bin/fdfind)" "$HOME/.local/bin/fd" 2>/dev/null || true
                    ;;
                redhat|fedora) sudo yum install -y fd-find || sudo dnf install -y fd-find || true ;;
            esac
            ;;
        nvm)
            if [ -d "$HOME/.nvm" ]; then
                log_warn "nvm already installed, skipping..."
                return
            fi
            curl -o- https://ghproxy.com/https://github.com/nvm-sh/nvm/raw/master/install.sh | bash 2>/dev/null || \
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
            if ! grep -q 'NVM_DIR' "$HOME/.zshrc" 2>/dev/null; then
                cat >> "$HOME/.zshrc" << 'EOF'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
            fi
            log_info "nvm installed. Run 'source ~/.zshrc' then 'nvm install --lts'"
            ;;
        pyenv)
            if [ -d "$HOME/.pyenv" ]; then
                log_warn "pyenv already installed, skipping..."
                return
            fi
            curl -L https://ghproxy.com/https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash 2>/dev/null || \
                curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
            if ! grep -q 'PYENV_ROOT' "$HOME/.zshrc" 2>/dev/null; then
                cat >> "$HOME/.zshrc" << 'EOF'

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
            fi
            log_info "pyenv installed. Run 'source ~/.zshrc' then 'pyenv install 3.12'"
            ;;
        go)
            if check_command go; then
                log_warn "Go already installed, skipping..."
                return
            fi
            local arch=$(uname -m)
            local go_version="1.22.1"
            local go_file=""
            case $os_type in
                macos)
                    [ "$arch" = "arm64" ] && go_file="go${go_version}.darwin-arm64.tar.gz" || go_file="go${go_version}.darwin-amd64.tar.gz"
                    ;;
                *)
                    [ "$arch" = "aarch64" ] && go_file="go${go_version}.linux-arm64.tar.gz" || go_file="go${go_version}.linux-amd64.tar.gz"
                    ;;
            esac
            local tmp_dir=$(mktemp -d)
            curl -fsSL "https://golang.google.cn/dl/$go_file" -o "$tmp_dir/$go_file"
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf "$tmp_dir/$go_file"
            rm -rf "$tmp_dir"
            if ! grep -q '/usr/local/go/bin' "$HOME/.zshrc" 2>/dev/null; then
                cat >> "$HOME/.zshrc" << 'EOF'

export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF
            fi
            log_info "Go installed successfully"
            ;;
        rust)
            if check_command rustc; then
                log_warn "Rust already installed, skipping..."
                return
            fi
            export RUSTUP_DIST_SERVER="https://rsproxy.cn"
            export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
            curl -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y
            if ! grep -q 'CARGO_HOME' "$HOME/.zshrc" 2>/dev/null; then
                cat >> "$HOME/.zshrc" << 'EOF'

export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
. "$HOME/.cargo/env"
EOF
            fi
            log_info "Rust installed successfully"
            ;;
        starship)
            if check_command starship; then
                log_warn "Starship already installed, skipping..."
                return
            fi
            local arch=$(uname -m)
            local starship_file=""
            case $os_type in
                macos)
                    [ "$arch" = "arm64" ] && starship_file="starship-aarch64-apple-darwin.tar.gz" || starship_file="starship-x86_64-apple-darwin.tar.gz"
                    ;;
                *)
                    [ "$arch" = "aarch64" ] && starship_file="starship-aarch64-unknown-linux-gnu.tar.gz" || starship_file="starship-x86_64-unknown-linux-gnu.tar.gz"
                    ;;
            esac
            local tmp_dir=$(mktemp -d)
            curl -fsSL "https://ghproxy.com/https://github.com/starship/starship/releases/latest/download/$starship_file" -o "$tmp_dir/$starship_file" || \
                curl -fsSL "https://github.com/starship/starship/releases/latest/download/$starship_file" -o "$tmp_dir/$starship_file"
            tar -xzf "$tmp_dir/$starship_file" -C "$tmp_dir"
            mkdir -p "$HOME/.local/bin"
            mv "$tmp_dir/starship" "$HOME/.local/bin/"
            chmod +x "$HOME/.local/bin/starship"
            rm -rf "$tmp_dir"
            if ! grep -q 'starship' "$HOME/.zshrc" 2>/dev/null; then
                cat >> "$HOME/.zshrc" << 'EOF'

eval "$(starship init zsh)"
EOF
            fi
            if ! grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null; then
                sed -i.bak '1i export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"
                rm -f "${HOME}/.zshrc.bak"
            fi
            log_info "Starship installed. Config: starship config or ~/.config/starship.toml"
            ;;
        zoxide)
            if check_command zoxide; then
                log_warn "zoxide already installed, skipping..."
                return
            fi
            curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            if ! grep -q 'zoxide' "$HOME/.zshrc" 2>/dev/null; then
                cat >> "$HOME/.zshrc" << 'EOF'

eval "$(zoxide init zsh)"
EOF
            fi
            log_info "zoxide installed. Use 'z' for smart directory navigation"
            ;;
    esac
}

install_selected_tools() {
    if [ ${#SELECTED_TOOLS[@]} -eq 0 ]; then
        return
    fi
    
    log_info "Installing selected tools: ${SELECTED_TOOLS[*]}"
    echo ""
    
    for tool in "${SELECTED_TOOLS[@]}"; do
        log_info "Installing $tool..."
        install_tool "$tool"
    done
}

main() {
    parse_args "$@"
    
    if [ "$INTERACTIVE" = true ] && [ ${#SELECTED_TOOLS[@]} -eq 0 ]; then
        show_interactive_menu
    fi
    
    log_info "Starting installation script..."
    log_info "Detected OS: $(detect_os)"
    
    local os_type=$(detect_os)
    
    if [ "$os_type" = "unknown" ]; then
        log_error "Unsupported operating system"
        exit 1
    fi
    
    install_dependencies "$os_type"
    install_oh_my_zsh
    install_zsh_plugins
    configure_zsh
    install_miniforge
    change_default_shell
    
    install_selected_tools
    
    echo ""
    log_info "Installation completed!"
    echo ""
    log_info "To start using Zsh now, run: exec zsh"
    log_info "Or reconnect SSH to use Zsh as default shell"
}

main "$@"
