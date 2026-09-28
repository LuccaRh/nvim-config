-- servidores LSP: o mason instala, o mason-lspconfig liga, e aqui
-- ficam os atalhos (gd, gD, gr, K, ...)
return {
    {
        'mason-org/mason.nvim',
        opts = {},
    },
    {
        'mason-org/mason-lspconfig.nvim',
        dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig', 'saghen/blink.cmp' },
        opts = { ensure_installed = { 'basedpyright', 'vtsls' } },
        config = function(_, o)
            vim.lsp.config('basedpyright', {
                settings = {
                    basedpyright = {
                        analysis = {
                            typeCheckingMode = 'standard',
                        },
                    },
                },
            })

            require('mason-lspconfig').setup(o)

            -- Pula para a definicao do simbolo sob o cursor.
            --   split = nil        -> troca o arquivo da janela atual
            --   split = 'vsplit'   -> abre a definicao numa janela nova ao lado
            --   split = 'split'    -> abre numa janela nova embaixo
            -- Se o servidor devolver mais de um candidato, cai no telescope
            -- (e la dentro <C-v> / <C-x> tambem abrem em split).
            local function ir_para_definicao(split)
                return function()
                    vim.lsp.buf.definition({
                        on_list = function(res)
                            if #res.items == 0 then
                                vim.notify('Nenhuma definicao encontrada', vim.log.levels.WARN)
                                return
                            end
                            if #res.items > 1 then
                                require('telescope.builtin').lsp_definitions({ jump_type = split or 'never' })
                                return
                            end
                            local item = res.items[1]
                            if split then
                                vim.cmd(split)
                            else
                                vim.cmd("normal! m'")   -- marca o ponto de partida no jumplist
                            end
                            if vim.fn.fnamemodify(item.filename, ':p') ~= vim.api.nvim_buf_get_name(0) then
                                vim.cmd('edit ' .. vim.fn.fnameescape(item.filename))
                            end
                            vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(item.col - 1, 0) })
                            vim.cmd('normal! zz')
                        end,
                    })
                end
            end

            -- Mesma coisa, mas disparada pelo mouse: o clique ainda nao moveu o
            -- cursor quando o mapeamento roda, entao pegamos a posicao do clique.
            local function definicao_no_clique(split)
                return function()
                    local m = vim.fn.getmousepos()
                    if m.winid == 0 or m.line == 0 then return end
                    vim.api.nvim_set_current_win(m.winid)
                    vim.api.nvim_win_set_cursor(m.winid, { m.line, math.max(m.column - 1, 0) })
                    ir_para_definicao(split)()
                end
            end

            vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(ev)
                local map = function(k, fn, d) vim.keymap.set('n', k, fn, { buffer = ev.buf, desc = d }) end
                local t = require('telescope.builtin')

                map('gd', ir_para_definicao(), 'Definicao (mesma janela)')
                map('gD', ir_para_definicao('vsplit'), 'Definicao em split vertical')
                map('gS', ir_para_definicao('split'), 'Definicao em split horizontal')
                map('gy', vim.lsp.buf.type_definition, 'Definicao do tipo')
                map('gi', t.lsp_implementations, 'Implementacoes')
                map('gr', t.lsp_references, 'Referencias reais')

                -- ctrl+clique       -> vai para a definicao (igual vscode)
                -- ctrl+shift+clique -> abre a definicao num split ao lado
                -- <C-o> volta; o botao "voltar" do mouse faz o mesmo
                map('<C-LeftMouse>', definicao_no_clique(), 'Definicao (ctrl+clique)')
                map('<C-S-LeftMouse>', definicao_no_clique('vsplit'), 'Definicao em split (ctrl+shift+clique)')
                map('<X1Mouse>', '<C-o>', 'Voltar')
                map('<X2Mouse>', '<C-i>', 'Avancar')

                map('K', vim.lsp.buf.hover, 'Hover')
                map('<leader>rn', vim.lsp.buf.rename, 'Renomear simbolo')
                map('<leader>ca', vim.lsp.buf.code_action, 'Acoes de codigo')
            end,
            })
        end,
    },
}
