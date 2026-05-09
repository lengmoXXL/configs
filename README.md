# configs

```
configs/
├── install.sh                  # 确保 bashrc 加载 ~/.config/env.d/*.sh
├── install/                    # 外部依赖安装脚本
│   ├── install-basic-tools.sh  # 安装基础命令行工具
│   ├── install-cc-switch-cli.sh # 安装 cc-switch-cli
│   ├── install-clash-for-linux.sh # 安装 Clash for Linux
│   ├── install-claude-code.sh  # 安装 Claude Code
│   ├── install-fd.sh           # 安装 fd 到 ~/.local/bin
│   ├── install-fonts.sh        # 安装 Nerd Fonts 字体 (sarasa/aurulent)
│   ├── install-go.sh           # 安装 Go 到 ~/.local/go
│   ├── install-mytask.sh       # 安装 mytask 工具
│   ├── install-node.sh         # 安装 Node.js 到 ~/.local/node
│   ├── install-nvim.sh         # 从源码编译安装 Neovim
│   ├── install-rust.sh         # 安装 Rust 到 ~/.local/rust
│   ├── install-tldr.sh         # 安装 tldr 命令行帮助工具
│   ├── install-tmux.sh         # 从源码编译安装 tmux
│   ├── install-tree-sitter.sh  # 安装 tree-sitter-cli
│   ├── install-zig.sh          # 安装 Zig 到 ~/.local/zig
│   ├── lsp/                    # LSP 安装脚本
│   │   ├── install-bash-lsp.sh # 安装 bash-language-server
│   │   ├── install-lua-lsp.sh  # 安装 lua-language-server
│   │   ├── install-markdown-oxide.sh # 安装 markdown-oxide
│   │   ├── install-pyright-lsp.sh # 安装 pyright
│   │   ├── install-rust-analyzer-lsp.sh # 安装 rust-analyzer
│   │   ├── install-typescript-lsp.sh # 安装 typescript-language-server
│   │   └── install-typos-lsp.sh # 安装 typos-lsp
│   └── sys/                    # yum/system package 相关脚本
│       ├── install-clang.sh    # 安装 clang/clangd
│       └── install-python.sh   # 使用 uv 创建 Python 3.11 虚拟环境
├── configs/
│   ├── install-nvim-config.sh  # 安装 nvim 配置到 ~/.config/nvim
│   ├── install-tmux-config.sh  # 安装 tmux 配置到 ~/.tmux.conf
│   ├── install-codex-config.sh # 更新 Codex AGENTS.md 规则
│   ├── codex/                  # Codex 配置
│   │   └── AGENTS.md           # Codex 全局规则
│   ├── nvim/                   # Neovim 配置
│   │   ├── init.lua
│   │   └── lua/
│   │       ├── plugins/        # 插件配置
│   │       │   └── ...
│   │       └── themes/         # 主题配置
│   │           └── ...
│   └── tmux/                   # tmux 配置
│       └── tmux.conf           # 开启鼠标与基础终端设置
└── tools/
    ├── codex_batch.py          # Codex 批处理脚本
    ├── install-codex-batch.sh  # 安装 codex-batch
    ├── install-pj.sh           # 安装 pj 环境切换器
    └── pj/                     # pj 工具源码
        └── ...
```
