# configs

## GitHub Release 安装

部分安装脚本使用固定版本的 GitHub Release 包。需要国内代理时传 `-cn`，代理前缀固定为 `https://gh-proxy.com/`。

```bash
./install/install-fd.sh -cn
./tools/github-release-latest.sh fd
```

升级固定版本时，先用 `tools/github-release-latest.sh` 查询最新 tag，再手动修改对应安装脚本里的默认版本。

## 文件内容

```
configs/
├── install.sh                  # 确保 bashrc 加载 ~/.config/env.d/*.sh
├── install/                    # 外部依赖安装脚本
│   ├── install-basic-tools.sh  # 安装基础命令行工具
│   ├── install-clash-for-linux.sh # 安装 Clash for Linux
│   ├── install-clashctl.sh     # 从 wnlen/clash-for-linux 安装 clashctl
│   ├── install-codex.sh        # 从 GitHub Release 安装/更新 Codex CLI
│   ├── install-fd.sh           # 安装 fd 到 ~/.local/bin
│   ├── install-fonts.sh        # 安装 Nerd Fonts 字体 (sarasa/aurulent)
│   ├── install-go.sh           # 安装 Go 到 ~/.local/go
│   ├── install-herdr.sh        # 从 GitHub Release 安装/更新 Herdr
│   ├── install-hermes-agent.sh # 安装 Hermes Agent
│   ├── install-mytask.sh       # 安装 mytask 工具
│   ├── install-node.sh         # 安装 Node.js 到 ~/.local/node
│   ├── install-nvim.sh         # 从源码编译安装 Neovim
│   ├── install-opencode.sh     # 从 GitHub Release 安装 opencode
│   ├── install-ossutil.sh      # 安装 ossutil 到 ~/.local/bin
│   ├── install-pi-agent.sh     # 从 npm 安装/更新 Pi Agent
│   ├── install-playwright.sh   # 安装 Playwright 与 Chromium
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
│   │   ├── install-starpls-lsp.sh # 安装 starpls
│   │   ├── install-typescript-lsp.sh # 安装 typescript-language-server
│   │   └── install-typos-lsp.sh # 安装 typos-lsp
│   └── sys/                    # yum/system package 相关脚本
│       ├── install-clang.sh    # 安装 clang/clangd
│       └── install-python.sh   # 使用 uv 创建 Python 3.11 虚拟环境
├── configs/
│   ├── install-nvim-config.sh  # 安装 nvim 配置到 ~/.config/nvim
│   ├── install-tmux-config.sh  # 安装 tmux 配置与 TPM
│   ├── install-herdr-config.sh # 安装 Herdr 配置到 ~/.config/herdr
│   ├── install-pi-extensions.sh # 安装 Plannotator/pi-simplify extensions
│   ├── install-opencode-config.py # 安装 opencode provider 配置
│   ├── install-pi-config.py    # 安装 Pi models/settings/themes 配置
│   ├── install-agents.sh       # 一次性安装 codex/opencode 的 AGENTS.md 规则
│   ├── agents/                 # AGENTS.md 提示词
│   │   ├── common.md           # 通用提示词
│   │   ├── codex.md            # Codex 专属提示词
│   │   └── opencode.md         # OpenCode 专属提示词
│   ├── herdr/                  # Herdr 配置
│   │   └── config.toml         # Herdr 配置：vscode.nvim dark palette、Ctrl-Space 前缀、无 pane 边框与单 tab 隐藏
│   ├── nvim/                   # Neovim 配置
│   │   ├── init.lua
│   │   └── lua/
│   │       ├── project_filetypes.lua # 按 git URL 应用 filetype 覆盖
│   │       ├── plugins/        # 插件配置
│   │       │   └── ...
│   │       └── themes/         # 主题配置
│   │           └── ...
│   ├── opencode/               # OpenCode 配置
│   │   └── opencode.json       # Provider/model 配置（apiKey 引用 secrets KV）
│   ├── pi/                     # Pi 配置
│   │   ├── models.json         # Pi provider/model 配置（apiKey 引用 secrets KV）
│   │   ├── settings.json       # Pi 默认设置
│   │   └── themes/             # Pi 主题 JSON 文件
│   │       └── gray.json
│   └── tmux/                   # tmux 配置
│       └── tmux.conf           # 开启鼠标、基础终端设置与 tmux 插件
├── skills/
│   ├── install-frontend-draw.sh # 安装 frontend-draw skill
│   ├── install-neovim-skill.sh # 从 GitHub 安装 neovim-skill
│   ├── install-style-check.sh  # 安装 style-check skill
│   ├── frontend-draw/          # frontend-draw skill 源码
│   └── style-check/            # style-check skill 源码
└── tools/
    ├── codex_batch.py          # Codex 批处理脚本
    ├── install-codex-batch.sh  # 安装 codex-batch
    ├── nvim_ft.py              # 按 git URL 维护 Neovim filetypes.json
    ├── github-release-latest.sh # 查询 GitHub Release 最新版本
    ├── install-nvim-ft.sh      # 安装 nvim-ft
    ├── install-prd.sh          # 安装 prd
    ├── secrets.sh              # 同步 .secrets provider API keys
    ├── prd/                    # prd TypeScript 源码与构建配置
    │   └── src/preview_server.ts # 为本机文件生成 HTTP 预览 URL
    ├── install-pj.sh           # 安装 pj 仓库命令工具
    └── pj/                     # pj 工具源码
        └── ...
```
