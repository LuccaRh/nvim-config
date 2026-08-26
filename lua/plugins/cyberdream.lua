-- tema
return {
    'scottmckendry/cyberdream.nvim',
    lazy = false,
    priority = 1000,
    config = function()
        require('cyberdream').setup({
            transparent = true,      -- deixa passar o fundo do terminal
            italic_comments = true,
            hide_fillchars = true,   -- some com os ~ das linhas vazias
            borderless_pickers = false,
            terminal_colors = true,
        })
        vim.cmd.colorscheme('cyberdream')
        vim.api.nvim_set_hl(0, 'VirtColumn', { fg = '#1E4247' })
    end,
}
