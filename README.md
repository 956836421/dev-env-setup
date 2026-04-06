# Development Environment Setup Script

一键配置开发环境的 Shell 脚本，支持 macOS 和 Linux。

## 功能

### 必装项
- **Oh My Zsh** - Zsh 配置框架
- **zsh-syntax-highlighting** - 语法高亮插件
- **zsh-autosuggestions** - 自动建议插件
- **ys 主题** - 简洁美观的 Zsh 主题
- **Miniforge** - Conda 发行版，配置清华镜像源

### 可选工具

**CLI 工具：**
| 工具 | 说明 |
|------|------|
| htop | 进程监控 |
| tmux | 终端复用 |
| tree | 目录树显示 |
| ripgrep (rg) | 快速搜索 |
| fzf | 模糊搜索 |
| bat | 带语法高亮的 cat |
| eza | 现代化 ls |
| fd | 快速 find |
| jq | JSON 处理 |

**开发环境：**
| 工具 | 说明 |
|------|------|
| nvm | Node.js 版本管理 |
| pyenv | Python 版本管理 |
| go | Go 编程语言 |
| rust | Rust 编程语言 |

**其他：**
| 工具 | 说明 |
|------|------|
| starship | 跨平台美观提示符 |
| zoxide | 智能 cd 命令 |

## 使用方法

### 交互模式（推荐）
```bash
chmod +x setup_dev_env.sh
./setup_dev_env.sh
```

### 命令行模式
```bash
# 安装指定工具
./setup_dev_env.sh --htop --fzf --ripgrep --starship -y

# 查看帮助
./setup_dev_env.sh -h
```

### 选项说明
```
-y, --yes      跳过交互确认
--htop         安装 htop
--tmux         安装 tmux
--tree         安装 tree
--ripgrep      安装 ripgrep
--fzf          安装 fzf
--bat          安装 bat
--eza          安装 eza
--fd           安装 fd
--jq           安装 jq
--nvm          安装 nvm
--pyenv        安装 pyenv
--go           安装 Go
--rust         安装 Rust
--starship     安装 Starship
--zoxide       安装 zoxide
```

## 支持系统

- macOS (Intel / Apple Silicon)
- Debian / Ubuntu
- RedHat / CentOS
- Fedora

## 国内镜像

脚本使用以下国内镜像加速：
- Oh My Zsh: Gitee
- Miniforge: 清华大学开源镜像站
- Conda: 清华大学开源镜像站
- Go: golang.google.cn
- Rust: rsproxy.cn
- GitHub 资源: ghproxy.com

## 安装后

运行以下命令启动 Zsh：
```bash
exec zsh
```

或重新 SSH 连接。

## 示例

```bash
# 交互式选择工具
./setup_dev_env.sh

# 只装 CLI 工具
./setup_dev_env.sh --htop --tmux --ripgrep --fzf --bat --eza --fd --jq -y

# 安装开发环境
./setup_dev_env.sh --nvm --pyenv --go --rust -y

# 全部安装
./setup_dev_env.sh --htop --tmux --tree --ripgrep --fzf --bat --eza --fd --jq --nvm --pyenv --go --rust --starship --zoxide -y
```

## License

MIT
