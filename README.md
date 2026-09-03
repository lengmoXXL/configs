# configs

## 文件内容

```
configs/
├── AGENTS.md -> README.md
├── README.md
├── install/                    # 所有安装脚本，一个脚本只做一件事
│   ├── agent-prompts.sh
│   ├── clash-for-linux.sh
│   ├── clashctl.sh
│   ├── cmake.sh
│   ├── codex.sh
│   ├── codex-batch.sh
│   ├── doc-research.sh         # doc-research CLI（固定 commit，对比远端提示更新）
│   ├── doc-research-init.sh
│   ├── dprint.sh
│   ├── fd.sh
│   ├── fonts.sh
│   ├── fzf.sh
│   ├── gh.sh
│   ├── ghostty-config.sh
│   ├── ghostty-terminfo.sh
│   ├── git-prune-merged.sh
│   ├── herdr.sh
│   ├── herdr-config.sh
│   ├── hermes-agent.sh
│   ├── kimi.sh
│   ├── kimi-config.sh
│   ├── nvim.sh
│   ├── nvim-config.sh
│   ├── nvim-ft.sh
│   ├── oh-my-bash.sh           # Linux: Oh My Bash + ~/.bashrc（env.d 加载、PATH）
│   ├── oh-my-zsh.sh            # macOS: Oh My Zsh + ~/.zshrc（env.d 加载、PATH）
│   ├── opencode.sh
│   ├── opencode-config.py
│   ├── ossutil.sh
│   ├── perf-to-profile.sh
│   ├── pi-agent.sh
│   ├── pi-config.py
│   ├── pi-extensions.sh
│   ├── pj.sh
│   ├── playwright.sh
│   ├── prd.sh
│   ├── ripgrep.sh
│   ├── style-check.sh
│   ├── tldr.sh
│   ├── tmux.sh
│   ├── tmux-config.sh
│   ├── tree-sitter.sh
│   ├── uv.sh
│   ├── compiler/               # 语言编译器/运行时
│   │   ├── clang.sh
│   │   ├── go.sh
│   │   ├── node.sh
│   │   ├── python.sh
│   │   ├── rust.sh
│   │   └── zig.sh
│   ├── lsp/
│   │   ├── bash-lsp.sh
│   │   ├── lua-lsp.sh
│   │   ├── markdown-oxide.sh
│   │   ├── pyright-lsp.sh
│   │   ├── rust-analyzer-lsp.sh
│   │   ├── starpls-lsp.sh
│   │   ├── typescript-lsp.sh
│   │   └── typos-lsp.sh
│   └── skill/                  # skill 安装
│       ├── code-report.sh
│       ├── code-style.sh
│       ├── frontend-draw.sh
│       └── neovim-skill.sh
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
