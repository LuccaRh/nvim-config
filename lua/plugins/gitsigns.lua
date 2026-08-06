-- mostrar estado git (unstaged/staged/commited) de uma edicao no codigo
return {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
        -- sinais na coluna da esquerda: + adicionado, ~ mudado, _ deletado
        signs = {
            add          = { text = '+' },
            change       = { text = '~' },
            delete       = { text = '_' },
            topdelete    = { text = '‾' },
            changedelete = { text = '~' },
            untracked    = { text = '┆' },
        },
        signs_staged_enable = true,   -- sinais diferentes para o que ja esta em stage
        on_attach = function(bufnr)
            local gs = require('gitsigns')
            -- pular entre as mudancas do arquivo
            vim.keymap.set('n', ']h', function() gs.nav_hunk('next') end, { buffer = bufnr, desc = 'Proximo hunk' })
            vim.keymap.set('n', '[h', function() gs.nav_hunk('prev') end, { buffer = bufnr, desc = 'Hunk anterior' })
        end,
    },
}
