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
├── install.sh                  # 安装 Oh My Zsh(macOS)/Oh My Bash(Linux)，rc 文件加载 ~/.config/env.d/*.sh
├── install/                    # 外部依赖安装脚本
│   ├── install-basic-tools.sh  # 安装基础命令行工具
│   ├── install-clash-for-linux.sh # 安装 Clash for Linux
│   ├── install-clashctl.sh     # 从 wnlen/clash-for-linux 安装 clashctl
│   ├── install-codex.sh        # 从 GitHub Release 安装/更新 Codex CLI
│   ├── install-fd.sh           # 安装 fd 到 ~/.local/bin
│   ├── install-fonts.sh        # 安装 Nerd Fonts 字体 (sarasa/aurulent/droid)
│   ├── install-go.sh           # 安装 Go 到 ~/.local/go
│   ├── install-ghostty-terminfo.sh # 在服务器安装 xterm-ghostty terminfo（内嵌条目，无需联网）
│   ├── install-herdr.sh        # 从 GitHub Release 安装/更新 Herdr
│   ├── install-hermes-agent.sh # 安装 Hermes Agent
│   ├── install-kimi.sh        # 通过官方脚本安装/更新 Kimi Code CLI
│   ├── install-mytask.sh       # 安装 mytask 工具
│   ├── install-node.sh         # 安装 Node.js 到 ~/.local/node
│   ├── install-nvim.sh         # 安装 Neovim（macOS 预编译包 / Linux 源码编译）
│   ├── install-opencode.sh     # 从 GitHub Release 安装 opencode
│   ├── install-ossutil.sh      # 安装 ossutil 到 ~/.local/bin
│   ├── install-perf-to-profile.sh # 从 OSS 安装预编译 perf_to_profile
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
│   ├── install-ghostty-config.sh # 安装 Ghostty 配置到 ~/.config/ghostty
│   ├── install-kimi-config.sh  # 安装 Kimi Code 主题到 ~/.kimi-code/themes
│   ├── install-pi-extensions.sh # 安装自研 Pi extensions
│   ├── install-opencode-config.py # 安装 opencode provider 配置
│   ├── install-pi-config.py    # 安装 Pi models/settings/themes/pi-footer 配置
│   ├── install-agents.sh       # 安装 AGENTS.md 规则（脚本内声明 agent 与 prompt 的关联）
│   ├── agents/                 # 按语义命名的 AGENTS.md 提示词
│   ├── ghostty/                # Ghostty 配置
│   │   └── config              # 字体、Dark Modern 主题、滚动与剪贴板行为
│   │   ├── inline-functions.md # 优先内联小函数，避免抽出过小的 helper
│   │   ├── editing-constraints.md # 编辑约束：ASCII 优先、read/replace 编辑、脏 worktree 保护
│   │   └── git-safety.md       # git 状态修改需当轮明确授权
│   ├── herdr/                  # Herdr 配置
│   │   └── config.toml         # Herdr 配置：vscode.nvim dark palette、Ctrl-Space 前缀、无 pane 边框与单 tab 隐藏
│   ├── kimi/                   # Kimi Code 配置
│   │   └── themes/             # Kimi Code 主题 JSON 文件
│   │       └── gray.json       # 极简灰调暗色主题
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
│   │   ├── settings.json       # Pi 默认设置（packages 声明外部插件，pi 启动时自动安装）
│   │   ├── pi-footer.json      # pi-footer 插件配置：模型、思考深度、上下文与右侧 MIN/MAX 状态
│   │   ├── extensions/         # 自研 Pi 扩展（安装到 ~/.pi/agent/extensions）
│   │   │   ├── bash-highlight.ts # bash 工具调用命令的 shell 关键词高亮（执行委托内置实现）
│   │   │   ├── flat-editor.ts  # 扁平无边框输入框：3 行高、› 提示符、灰背景
│   │   │   └── max-min.ts      # /max-loop、/min-loop 启动 MAX/MIN 循环，working 中执行会打断并自动进入，连续三次无变更退出，打断保留状态
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
    ├── build-perf-to-profile.sh # 构建并可选发布 perf_to_profile 到 OSS
    ├── codex_batch.py          # Codex 批处理脚本
    ├── install-codex-batch.sh  # 安装 codex-batch
    ├── nvim_ft.py              # 按 git URL 维护 Neovim filetypes.json
    ├── github-release-latest.sh # 查询 GitHub Release 最新版本
    ├── git-prune-merged.sh     # 删除已合并到主分支的本地分支
    ├── install-git-prune-merged.sh # 安装 git-prune-merged 到 ~/.local/bin
    ├── install-nvim-ft.sh      # 安装 nvim-ft
    ├── install-prd.sh          # 安装 prd
    ├── secrets.sh              # 同步 .secrets provider API keys
    ├── prd/                    # prd TypeScript 源码与构建配置
    │   └── src/preview_server.ts # 为本机文件生成 HTTP 预览 URL
    ├── install-pj.sh           # 安装 pj 仓库命令工具
    └── pj/                     # pj 工具源码
        └── ...
```
