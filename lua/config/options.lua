-- leader PRECISA vir antes dos plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- umas poucas opções básicas
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.termguicolors = true
vim.opt.colorcolumn = '80'

vim.opt.wildmenu = true
vim.opt.wildmode = 'longest:full,full'
vim.opt.tabstop = 4        -- largura visual de um <Tab>
vim.opt.shiftwidth = 4     -- quantos espaços o >> e o > aplicam
vim.opt.softtabstop = 4    -- quantos espaços o Tab insere ao digitar
vim.opt.expandtab = true   -- Tab vira espaços (não o caractere \t)
