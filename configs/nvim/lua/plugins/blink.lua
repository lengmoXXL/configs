return {
  'saghen/blink.cmp',
  event = 'InsertEnter',
  version = '1.*',
  opts = {
    signature = { enabled = true },
    keymap = {
      preset = 'default',
      ['<Tab>'] = { 'select_next', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'fallback' },
    },
    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = 'mono',
    },
    fuzzy = {
      max_typos = function(keyword)
        -- 包含中文则允许全部 typos，纯英文按长度/4
        if keyword:find('[\228-\233]') then
          return #keyword
        end
        return math.floor(#keyword / 4)
      end,
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
  },
}
