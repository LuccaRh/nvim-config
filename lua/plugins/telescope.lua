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
        telescope.setup({
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
    end,
}
