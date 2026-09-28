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

-- qualidade de vida
vim.opt.signcolumn = 'yes'    -- coluna de sinais sempre aberta: o texto para de
                              -- pular de lado quando aparece um erro ou sinal do git
vim.opt.updatetime = 200      -- afeta blame virtual e hover (padrao: 4 segundos)
vim.opt.timeoutlen = 400      -- espera por atalhos de varias teclas
vim.opt.splitright = true     -- :vsplit abre a janela nova a DIREITA
vim.opt.splitbelow = true     -- :split abre a janela nova EMBAIXO
vim.opt.ignorecase = true     -- busca ignora maiusculas...
vim.opt.smartcase = true      -- ...a nao ser que voce digite uma maiuscula
vim.opt.undofile = true       -- undo sobrevive a fechar e reabrir o arquivo
vim.opt.scrolloff = 6         -- nunca cola o cursor na borda de cima/baixo
vim.opt.inccommand = 'split'  -- preview ao vivo do :%s/foo/bar
vim.opt.confirm = true        -- pergunta em vez de recusar quando ha mudanca nao salva
