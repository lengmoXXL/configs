# configs

```
configs/
├── install.sh                  # 确保 bashrc 加载 ~/.config/env.d/*.sh
├── configs/
│   ├── install-nvim-config.sh  # 安装 nvim 配置到 ~/.config/nvim
│   ├── install-tmux-config.sh  # 安装 tmux 配置到 ~/.tmux.conf
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
    ├── install-fonts.sh        # 安装 Nerd Fonts 字体 (sarasa/aurulent)
    ├── install-go.sh           # 安装 Go 到 ~/.local/go
    ├── install-mytask.sh       # 安装 mytask 工具
    ├── install-node.sh         # 安装 Node.js 到 ~/.local/node
    ├── install-nvim.sh         # 从源码编译安装 Neovim
    ├── install-pj.sh           # 安装 pj 环境切换器
    ├── install-rust.sh         # 安装 Rust 到 ~/.local/rust
    ├── install-tmux.sh         # 从源码编译安装 tmux
    ├── install-tldr.sh         # 安装 tldr 命令行帮助工具
    ├── install-tree-sitter.sh  # 安装 tree-sitter-cli
    ├── lsp/                    # LSP 相关安装脚本
    │   ├── install-bash-lsp.sh # 安装 bash-language-server
    │   ├── install-ds-pinyin-lsp.sh # 安装 ds-pinyin-lsp 二进制
    │   ├── install-lua-lsp.sh  # 安装 lua-language-server
    │   ├── install-markdown-oxide.sh # 安装 markdown-oxide (Markdown LSP)
    │   ├── install-rust-analyzer-lsp.sh # 安装 rust-analyzer
    │   ├── install-typescript-lsp.sh # 安装 typescript-language-server
    │   ├── install-typos-lsp.sh # 安装 typos-lsp (拼写检查)
    │   └── pinyin-dict-ctl.sh  # 拼音词典管理与词典安装
    ├── pj/                     # pj 工具源码
    │   └── ...
    └── sys/                    # yum/system package 相关脚本
        ├── install-clang.sh    # 安装 clang/clangd
        └── install-python.sh   # 使用 uv 创建 Python 3.11 虚拟环境
```
