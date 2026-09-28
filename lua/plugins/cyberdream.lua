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
        -- com transparent = true o cyberdream grava 'NONE' na cor 0 do
        -- terminal, que nao e uma cor valida: o lazygit e outros programas
        -- no :terminal ficam com as cores bagunçadas. Fixa um preto real.
        vim.g.terminal_color_0 = '#16181a'

        -- hide_fillchars zera o 'vert' tambem, deixando a divisoria das
        -- janelas invisivel (e impossivel de acertar com o mouse).
        -- Devolve so ela, mantendo o eob vazio que tira os ~.
        vim.opt.fillchars:append({ vert = '│' })
    end,
}
