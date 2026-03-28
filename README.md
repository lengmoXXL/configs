# configs

```
configs/
├── install.sh                  # 确保 bashrc 加载 ~/.config/env.d/*.sh
├── configs/
│   └── nvim/                   # Neovim 配置
│       ├── init.lua
│       └── lua/
│           ├── plugins/        # 插件配置
│           │   └── ...
│           └── themes/         # 主题配置
│               └── ...
└── tools/
    ├── install-bash-lsp.sh     # 安装 bash-language-server
    ├── install-go.sh           # 安装 Go 到 ~/.local/go
    ├── install-lua-lsp.sh      # 安装 lua-language-server
    ├── install-mytask.sh       # 安装 mytask 工具
    ├── install-node.sh         # 安装 Node.js 到 ~/.local/node
    ├── install-nvim.sh         # 安装 nvim 配置到 ~/.config/nvim
    ├── install-pj.sh           # 安装 pj 环境切换器
    ├── install-rust.sh         # 安装 Rust 到 ~/.local/rust
    ├── install-tree-sitter.sh  # 安装 tree-sitter-cli
    ├── install-typescript-lsp.sh # 安装 typescript-language-server
    ├── install-typos-lsp.sh    # 安装 typos-lsp (拼写检查)
    └── pj/                     # pj 工具源码
        └── ...
```