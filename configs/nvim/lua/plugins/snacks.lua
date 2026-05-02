local last_terminal_count = 1

local function hide_visible_terminals()
  local hidden = false
  for _, terminal in ipairs(Snacks.terminal.list()) do
    if terminal:valid() then
      terminal:hide()
      hidden = true
    end
  end
  return hidden
end

local function open_terminal(count)
  last_terminal_count = count

  Snacks.terminal(nil, {
    count = count,
    win = {
      position = "float",
      width = 0.99,
      height = 0.65,
      row = 0.30,
      border = "single",
      title_pos = "left",
      title = " Terminal " .. count .. " ",
    },
  })
end

local function toggle_recent_terminal()
  return function()
    if not hide_visible_terminals() then
      open_terminal(last_terminal_count)
    end
  end
end

local function switch_terminal(count)
  return function()
    hide_visible_terminals()
    open_terminal(count)
  end
end

return
{
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    picker = {
      enabled = true,
      layout = {
        preset = "bottom",
        hidden = { "preview" },
      },
      sources = {
        lsp_symbols = { keep_parents = true, filter = { yaml = true } },
      },
    },
    dashboard = { enabled = false },
    indent = { enabled = true, filter = function(buf) return vim.bo[buf].filetype ~= "markdown" end },
    scroll = { enabled = true },
    terminal = {
      win = {
        position = "float",
        width = 0.8,
        height = 0.7,
        row = 0.55,
        border = "single",
        title_pos = "left",
        title = " Terminal ",
      },
    },
    image = { enabled = false },
    words = { enabled = true },
  },
  keys = {
    -- Top Pickers & Explorer
    { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
    { "<M-.>", toggle_recent_terminal(), desc = "Toggle Recent Terminal", mode = { "n", "t" } },
    { "<M-t>1", switch_terminal(1), desc = "Switch to Terminal 1", mode = { "n", "t" } },
    { "<M-t>2", switch_terminal(2), desc = "Switch to Terminal 2", mode = { "n", "t" } },
    { "<M-t>3", switch_terminal(3), desc = "Switch to Terminal 3", mode = { "n", "t" } },
    { "<M-t>4", switch_terminal(4), desc = "Switch to Terminal 4", mode = { "n", "t" } },
    { "<M-t>5", switch_terminal(5), desc = "Switch to Terminal 5", mode = { "n", "t" } },
    { "<M-t>6", switch_terminal(6), desc = "Switch to Terminal 6", mode = { "n", "t" } },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>f.", function() Snacks.picker.files({ cwd = vim.fn.expand('%:p:h'), hidden = true }) end, desc = "Find Files (current file dir)" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
    -- git
    { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git Branches" },
    { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git Log" },
    { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git Log Line" },
    { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
    { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },
    -- Grep
    { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
    { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
    -- search
    { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
    { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
    { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>sr", function() Snacks.picker.resume() end, desc = "Resume" },
    { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    -- LSP
    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "Goto Definition",
    },
    { "<leader>gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "<leader>gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "<leader>gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "C[a]lls Incoming" },
    { "<leader>gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "C[a]lls Outgoing" },
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end

        -- Override print to use snacks for `:=` command
        if vim.fn.has("nvim-0.11") == 1 then
          vim._print = function(_, ...)
            dd(...)
          end
        else
          vim.print = _G.dd 
        end

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
      end,
    })
  end,
}
