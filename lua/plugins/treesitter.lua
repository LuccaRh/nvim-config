-- Entende a sintaxe do código
return {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    lazy = false,
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
        ensure_installed = { 'python', 'lua', 'bash', 'json', 'yaml', 'markdown', 'toml' },
        highlight = { enable = true },
        indent = { enable = true },
    },
}
