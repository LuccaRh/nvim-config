-- Telescope fuzzy finder
return {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
        local telescope = require('telescope')
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')

        -- fecha o buffer selecionado (ou os marcados com Tab) descartando alteracoes
        local force_delete_buffer = function(prompt_bufnr)
            local picker = action_state.get_current_picker(prompt_bufnr)
            picker:delete_selection(function(selection)
                return pcall(vim.api.nvim_buf_delete, selection.bufnr, { force = true })
            end)
        end

        telescope.setup({
            pickers = {
                buffers = {
                    mappings = {
                        i = {
                            ['<C-d>'] = actions.delete_buffer,
                            ['<M-d>'] = force_delete_buffer,
                        },
                        n = {
                            ['d'] = actions.delete_buffer,
                            ['D'] = force_delete_buffer,
                        },
                    },
                },
            },
            extensions = {
                fzf = {},
            },
        })
        telescope.load_extension('fzf')

        local t = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', t.find_files, { desc = 'Buscar arquivo' })
        vim.keymap.set('n', '<leader>fg', t.live_grep, { desc = 'Grep no projeto' })
        vim.keymap.set('n', '<leader>fb', t.buffers, { desc = 'Trocar buffer' })
        vim.keymap.set('n', '<leader>fs', t.lsp_dynamic_workspace_symbols, { desc = 'Buscar simbolo' })
        vim.keymap.set('n', '<leader>fd', function() t.diagnostics({ bufnr = 0 }) end, { desc = 'Erros do arquivo' })
        vim.keymap.set('n', '<leader>fD', t.diagnostics, { desc = 'Erros do projeto' })
    end,
}
