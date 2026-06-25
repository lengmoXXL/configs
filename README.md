# configs

## 国内网络模式

联网安装脚本支持 `-cn` 或 `--cn`：

```bash
./install/install-basic-tools.sh -cn
./install/install-node.sh -cn
./install/lsp/install-pyright-lsp.sh -cn
```

`-cn` 会启用 GitHub 代理、Playwright npmmirror、PyPI/uv 阿里云镜像、Rust 阿里云镜像、Cargo USTC 镜像与 Go goproxy.cn。npm registry 由 `install-node.sh -cn` 配置，其它 npm 脚本假定 npm 已经准备好。

常用覆盖变量：

```bash
GITHUB_PROXY=https://gh-proxy.com/ ./install/install-nvim.sh -cn
NPM_REGISTRY=https://registry.npmmirror.com ./install/install-node.sh -cn
ZIG_DOWNLOAD_BASE=https://ziglang.org/download ./install/install-zig.sh -cn
```

## 敏感配置

`.secrets/` 是本地明文敏感配置目录，不加入 git。默认同步到 `oss://lengmo-secrets/configs`，endpoint 为 `oss-cn-beijing.aliyuncs.com`。

```bash
./tools/secrets.sh init     # 创建 .secrets/ossutilconfig 和 .secrets/opencode.json 模板
./tools/secrets.sh push     # 把 .secrets 同步到 OSS
./tools/secrets.sh pull     # 从 OSS 同步到 .secrets
./tools/secrets.sh install  # 安装到 ~/.config/opencode/opencode.json 和 ~/.ossutilconfig
```

`init` 只生成模板，`.secrets/ossutilconfig` 里的 `accessKeyId` 和 `accessKeySecret` 需要手动填写。`push` 会拒绝上传空 AK/SK 的 ossconfig。

## 文件内容

```
configs/
├── install.sh                  # 确保 bashrc 加载 ~/.config/env.d/*.sh
├── install/                    # 外部依赖安装脚本
│   ├── install-basic-tools.sh  # 安装基础命令行工具
│   ├── install-cc-switch-cli.sh # 安装 cc-switch-cli
│   ├── install-clash-for-linux.sh # 安装 Clash for Linux
│   ├── install-claude-code.sh  # 安装 Claude Code
│   ├── install-codex.sh        # 从 GitHub Release 安装/更新 Codex CLI
│   ├── install-fd.sh           # 安装 fd 到 ~/.local/bin
│   ├── install-fonts.sh        # 安装 Nerd Fonts 字体 (sarasa/aurulent)
│   ├── install-go.sh           # 安装 Go 到 ~/.local/go
│   ├── install-mytask.sh       # 安装 mytask 工具
│   ├── install-node.sh         # 安装 Node.js 到 ~/.local/node
│   ├── install-nvim.sh         # 从源码编译安装 Neovim
│   ├── install-playwright.sh   # 安装 Playwright 与 Chromium
│   ├── install-rust.sh         # 安装 Rust 到 ~/.local/rust
│   ├── install-tldr.sh         # 安装 tldr 命令行帮助工具
│   ├── install-tmux.sh         # 从源码编译安装 tmux
│   ├── install-tree-sitter.sh  # 安装 tree-sitter-cli
│   ├── install-zig.sh          # 安装 Zig 到 ~/.local/zig
│   ├── lib/network.sh          # 统一 -cn 网络模式
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
│   ├── install-agents.sh       # 一次性安装 codex/opencode 的 AGENTS.md 规则
│   ├── agents/                 # AGENTS.md 提示词源码
│   │   ├── common.md           # 通用提示词
│   │   ├── codex.md            # Codex 专属提示词
│   │   └── opencode.md         # OpenCode 专属提示词
│   ├── nvim/                   # Neovim 配置
│   │   ├── init.lua
│   │   └── lua/
│   │       ├── project_filetypes.lua # 按 git URL 应用 filetype 覆盖
│   │       ├── plugins/        # 插件配置
│   │       │   └── ...
│   │       └── themes/         # 主题配置
│   │           └── ...
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
    ├── install-nvim-ft.sh      # 安装 nvim-ft
    ├── install-prd.sh          # 安装 prd
    ├── secrets.sh              # 同步与安装 .secrets 敏感配置
    ├── prd/                    # prd TypeScript 源码与构建配置
    │   └── src/preview_server.ts # 为本机文件生成 HTTP 预览 URL
    ├── install-pj.sh           # 安装 pj 环境切换器
    └── pj/                     # pj 工具源码
        └── ...
```
