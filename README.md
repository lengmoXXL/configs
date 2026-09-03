# configs

## 文件内容

```
configs/
├── AGENTS.md -> README.md
├── README.md
├── install/                    # 所有安装脚本，扁平放置，一个脚本只做一件事
│   ├── install-agents.sh
│   ├── install-bash-lsp.sh
│   ├── install-clang.sh
│   ├── install-clash-for-linux.sh
│   ├── install-clashctl.sh
│   ├── install-cmake.sh
│   ├── install-code-report.sh
│   ├── install-code-style.sh
│   ├── install-codex.sh
│   ├── install-codex-batch.sh
│   ├── install-doc-research.sh   # doc-research CLI（固定 commit，对比远端提示更新）
│   ├── install-doc-research-init.sh
│   ├── install-dprint.sh
│   ├── install-fd.sh
│   ├── install-fonts.sh
│   ├── install-frontend-draw.sh
│   ├── install-fzf.sh
│   ├── install-gh.sh
│   ├── install-ghostty-config.sh
│   ├── install-ghostty-terminfo.sh
│   ├── install-git-prune-merged.sh
│   ├── install-go.sh
│   ├── install-herdr.sh
│   ├── install-herdr-config.sh
│   ├── install-hermes-agent.sh
│   ├── install-kimi.sh
│   ├── install-kimi-config.sh
│   ├── install-lua-lsp.sh
│   ├── install-markdown-oxide.sh
│   ├── install-neovim-skill.sh
│   ├── install-node.sh
│   ├── install-nvim.sh
│   ├── install-nvim-config.sh
│   ├── install-nvim-ft.sh
│   ├── install-oh-my-bash.sh     # Linux: Oh My Bash + ~/.bashrc（env.d 加载、PATH）
│   ├── install-oh-my-zsh.sh      # macOS: Oh My Zsh + ~/.zshrc（env.d 加载、PATH）
│   ├── install-opencode.sh
│   ├── install-opencode-config.py
│   ├── install-ossutil.sh
│   ├── install-perf-to-profile.sh
│   ├── install-pi-agent.sh
│   ├── install-pi-config.py
│   ├── install-pi-extensions.sh
│   ├── install-pj.sh
│   ├── install-playwright.sh
│   ├── install-prd.sh
│   ├── install-python.sh
│   ├── install-pyright-lsp.sh
│   ├── install-ripgrep.sh
│   ├── install-rust.sh
│   ├── install-rust-analyzer-lsp.sh
│   ├── install-starpls-lsp.sh
│   ├── install-style-check.sh
│   ├── install-tldr.sh
│   ├── install-tmux.sh
│   ├── install-tmux-config.sh
│   ├── install-tree-sitter.sh
│   ├── install-typescript-lsp.sh
│   ├── install-typos-lsp.sh
│   ├── install-uv.sh
│   └── install-zig.sh
├── configs/
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
│   ├── code-report/
│   ├── code-style/
│   ├── frontend-draw/
│   └── publish-frontend-draw-assets.sh
└── tools/
    ├── build-perf-to-profile.sh
    ├── codex_batch.py
    ├── doc-research-init.sh      # 初始化文献调研项目（raw/tr/dist + 工作流 README）
    ├── github-release-latest.sh
    ├── git-prune-merged.sh
    ├── hermes/
    ├── nvim_ft.py               # 按 git URL 管理 Neovim filetype
    ├── pj/                      # 仓库命令工具
    │   └── ...
    ├── prd/                     # 本机文件 HTTP 预览工具
    │   └── src/preview_server.ts
    ├── secrets.sh               # 同步 provider API keys
    └── style-check.sh
```
