local snacks_tab = require('snacks_tab')
local snacks_terminal = require('snacks_terminal')

return
{
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = {
      enabled = true,
      size = 1.5 * 1024 * 1024,
    },
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
    scroll = { enabled = false },
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
    { "<leader><space>", function() Snacks.picker.recent() end, desc = "Recent" },
    { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>/", function() Snacks.picker.grep({ cwd = vim.fn.expand('%:p:h') }) end, desc = "Grep current file dir" },
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
    { "<leader>f.", function() Snacks.picker.files({ cwd = vim.fn.expand('%:p:h'), hidden = true }) end, desc = "Find Files (current file dir)" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>tt", snacks_tab.pick, desc = "Tabs" },
    { "<leader>tx", snacks_tab.close, desc = "Close Tab" },
    { "<M-t>c", snacks_terminal.create, desc = "Create Terminal", mode = { "n", "t" } },
    { "<M-t>p", snacks_terminal.pick, desc = "Pick Terminal", mode = { "n", "t" } },
    { "<M-t>r", snacks_terminal.rename_current, desc = "Rename Terminal", mode = { "n", "t" } },
    { "<M-t>t", snacks_terminal.toggle, desc = "Toggle Terminal", mode = { "n", "t" } },
    { "<M-t>x", snacks_terminal.close_current, desc = "Close Terminal", mode = { "n", "t" } },
    { "<M-.>", snacks_terminal.toggle, desc = "Toggle Terminal", mode = { "n", "t" } },
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
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "<leader>gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "<leader>gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "<leader>gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "C[a]lls Incoming" },
    { "<leader>gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "C[a]lls Outgoing" },
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
  },
  init = function()
    local group = vim.api.nvim_create_augroup("SnacksNormalBufferKeymaps", { clear = true })
    local set_buffer_keymap = function(bufnr)
      if vim.bo[bufnr].buftype ~= '' then
        return
      end

      vim.keymap.set("n", "qq", function()
        snacks_tab.close()
      end, { buffer = bufnr, desc = "Close Tab" })
    end

    set_buffer_keymap(vim.api.nvim_get_current_buf())
    vim.api.nvim_create_autocmd("BufEnter", {
      group = group,
      callback = function(args)
        set_buffer_keymap(args.buf)
      end,
    })

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
