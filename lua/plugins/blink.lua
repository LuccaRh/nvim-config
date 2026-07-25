-- autocomplete
return {
    'saghen/blink.cmp',
    version = '1.*',
    dependencies = { 'rafamadriz/friendly-snippets' },
    opts = {
        keymap = { preset = 'super-tab' },
        sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
        appearance = { nerd_font_variant = 'mono' },
    },
}
