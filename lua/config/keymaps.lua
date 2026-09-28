-- andar entre janelas sem <C-w>, ja que agora o fluxo usa splits
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Janela a esquerda' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Janela abaixo' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Janela acima' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Janela a direita' })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Limpar realce da busca' })

-- trocar de buffer (antes vinha do bufferline, que foi removido junto com a
-- barra de abas; a lista de buffers mesmo esta no telescope, <leader>fb)
vim.keymap.set('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Proximo buffer' })
vim.keymap.set('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Buffer anterior' })
