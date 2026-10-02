-- Adiciona arvore de arquivos
return {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons',
        'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree',
    keys = {
        { '<leader>e', '<cmd>Neotree toggle<CR>', desc = 'Explorer' },
    },
    opts = {
        filesystem = {
            filtered_items = {
                -- Mostra dotfiles e arquivos do .gitignore (os ignorados ficam com cor apagada)
                hide_dotfiles = false,
                hide_gitignored = false,
            },
        },
        window = {
            mappings = {
                -- Garante que H dentro da arvore alterne os ocultos, e nao troque de buffer
                ['H'] = 'toggle_hidden',
            },
        },
    },
}
