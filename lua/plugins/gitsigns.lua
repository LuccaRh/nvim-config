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
        -- autor + data + mensagem do commit no fim da linha do cursor
        current_line_blame = true,
        current_line_blame_opts = { delay = 250, virt_text_pos = 'eol', ignore_whitespace = true },
        current_line_blame_formatter = '    <author>, <author_time:%d/%m/%Y> · <summary>',
        on_attach = function(bufnr)
            local gs = require('gitsigns')
            -- pular entre as mudancas do arquivo (no estudo de commits,
            -- entre os trechos do commit, que ele deixa em b:estudo_trechos)
            local function pular(passo)
                local trechos = vim.b[bufnr].estudo_trechos
                if not trechos then return gs.nav_hunk(passo > 0 and 'next' or 'prev') end
                local cur, alvo = vim.fn.line('.'), nil
                for _, l in ipairs(trechos) do
                    if passo > 0 and l > cur and not alvo then alvo = l end
                    if passo < 0 and l < cur then alvo = l end
                end
                if alvo then vim.api.nvim_win_set_cursor(0, { alvo, 0 }) end
            end
            vim.keymap.set('n', ']h', function() pular(1) end, { buffer = bufnr, desc = 'Proximo hunk' })
            vim.keymap.set('n', '[h', function() pular(-1) end, { buffer = bufnr, desc = 'Hunk anterior' })
        end,
    },
}
