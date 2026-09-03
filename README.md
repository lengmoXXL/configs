# configs

## 文件内容

```
configs/
├── AGENTS.md -> README.md
├── README.md
├── install.sh                  # 安装 Oh My Zsh / Oh My Bash 与 env.d 加载
├── install/
│   ├── install-basic-tools.sh
│   ├── install-clash-for-linux.sh
│   ├── install-clashctl.sh
│   ├── install-codex.sh
│   ├── install-doc-research.sh   # doc-research CLI（固定 commit，对比远端提示更新）
│   ├── install-dprint.sh
│   ├── install-fd.sh
│   ├── install-fonts.sh
│   ├── install-gh.sh
│   ├── install-go.sh
│   ├── install-ghostty-terminfo.sh
│   ├── install-herdr.sh
│   ├── install-hermes-agent.sh
│   ├── install-kimi.sh
│   ├── install-node.sh
│   ├── install-nvim.sh
│   ├── install-opencode.sh
│   ├── install-ossutil.sh
│   ├── install-perf-to-profile.sh
│   ├── install-pi-agent.sh
│   ├── install-playwright.sh
│   ├── install-rust.sh
│   ├── install-tldr.sh
│   ├── install-tmux.sh
│   ├── install-tree-sitter.sh
│   ├── install-uv.sh
│   ├── install-zig.sh
│   ├── lsp/
│   │   ├── install-bash-lsp.sh
│   │   ├── install-lua-lsp.sh
│   │   ├── install-markdown-oxide.sh
│   │   ├── install-pyright-lsp.sh
│   │   ├── install-rust-analyzer-lsp.sh
│   │   ├── install-starpls-lsp.sh
│   │   ├── install-typescript-lsp.sh
│   │   └── install-typos-lsp.sh
│   └── sys/
│       ├── install-clang.sh
│       └── install-python.sh
├── configs/
│   ├── install-nvim-config.sh
│   ├── install-tmux-config.sh
│   ├── install-herdr-config.sh
│   ├── install-ghostty-config.sh
│   ├── install-kimi-config.sh
│   ├── install-pi-extensions.sh
│   ├── install-opencode-config.py
│   ├── install-pi-config.py
│   ├── install-agents.sh
│   ├── agents/
│   │   ├── editing-constraints.md
│   │   ├── git-safety.md
│   │   └── inline-functions.md
│   ├── ghostty/
│   │   └── config
│   ├── herdr/
│   │   └── config.toml
│   ├── kimi/
│   │   └── themes/
│   │       └── gray.json
│   ├── nvim/
│   │   ├── init.lua
│   │   ├── patches/
│   │   │   └── neogit-codediff-session-config.patch  # neogit 集成适配 codediff 新 API，由 neogit.lua 的 build 钩子自动应用
│   │   └── lua/
│   │       ├── project_filetypes.lua
│   │       ├── buffer_columns.lua
│   │       ├── caption_jump.lua
│   │       ├── plugins/
│   │       │   └── ...
│   │       └── themes/
│   │           └── ...
│   ├── opencode/
│   │   └── opencode.json
│   ├── pi/
│   │   ├── models.json
│   │   ├── settings.json
│   │   ├── pi-footer.json
│   │   ├── pi-plan-mode.json
│   │   ├── agents/
│   │   │   └── worker.md
│   │   ├── extensions/
│   │   │   ├── bash-highlight.ts
│   │   │   ├── flat-editor.ts
│   │   │   └── refine.ts
│   │   └── themes/
│   │       └── gray.json
│   └── tmux/
│       └── tmux.conf
├── skills/
│   ├── install-code-report.sh
│   ├── install-code-style.sh
│   ├── install-frontend-draw.sh
│   ├── install-neovim-skill.sh
│   ├── code-report/
│   ├── code-style/
│   └── frontend-draw/
└── tools/
    ├── build-perf-to-profile.sh
    ├── codex_batch.py
    ├── doc-research-init.sh      # 初始化文献调研项目（raw/tr/dist + 工作流 README）
    ├── install-codex-batch.sh
    ├── install-doc-research-init.sh
    ├── nvim_ft.py               # 按 git URL 管理 Neovim filetype
    ├── github-release-latest.sh
    ├── git-prune-merged.sh
    ├── install-git-prune-merged.sh
    ├── install-nvim-ft.sh
    ├── install-prd.sh
    ├── secrets.sh               # 同步 provider API keys
    ├── prd/                     # 本机文件 HTTP 预览工具
    │   └── src/preview_server.ts
    ├── install-pj.sh
    └── pj/                      # 仓库命令工具
        └── ...
```
