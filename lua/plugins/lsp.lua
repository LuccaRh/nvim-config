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

            vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(ev)
                local map = function(k, fn, d) vim.keymap.set('n', k, fn, { buffer = ev.buf, desc = d }) end
                local t = require('telescope.builtin')

                map('gd', t.lsp_definitions, 'Definicao')
                map('gD', vim.lsp.buf.type_definition, 'Definicao do tipo')
                map('gr', t.lsp_references, 'Referencias reais')

                map('K', vim.lsp.buf.hover, 'Hover')
                map('<leader>rn', vim.lsp.buf.rename, 'Renomear simbolo')
                map('<leader>ca', vim.lsp.buf.code_action, 'Acoes de codigo')
            end,
            })
        end,
    },
}
