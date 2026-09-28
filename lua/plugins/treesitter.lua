-- Entende a sintaxe do código
return {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    lazy = false,
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
        ensure_installed = {
            'python', 'lua', 'bash', 'json', 'yaml', 'markdown', 'markdown_inline', 'toml',
            -- voce usa o vtsls (typescript) mas nao tinha o parser: sem isso o
            -- highlight de .ts/.tsx cai no regex antigo do vim
            'typescript', 'tsx', 'javascript', 'html', 'css',
            -- deixam os buffers do lazygit e as mensagens de commit legiveis
            'diff', 'gitcommit', 'git_rebase',
            'vim', 'vimdoc', 'query', 'regex',
        },
        highlight = { enable = true },
        indent = { enable = true },
    },
}
