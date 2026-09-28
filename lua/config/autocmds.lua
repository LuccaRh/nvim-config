-- remover espacos no fim das linhas ao salvar.
-- markdown fica de fora: la, dois espacos no fim da linha SAO uma quebra de
-- linha, e o autosave estava apagando eles enquanto voce digitava.
local sem_trim = { markdown = true, diff = true, gitcommit = true }
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  callback = function(ev)
    if sem_trim[vim.bo[ev.buf].filetype] then return end
    local view = vim.fn.winsaveview()   -- guarda cursor E rolagem da janela
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- salvar automaticamente
vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave', 'FocusLost' }, {
  pattern = '*',
  callback = function()
    if vim.bo.modified and vim.bo.buftype == '' and vim.fn.expand('%') ~= '' then
      vim.cmd('silent! write')
    end
  end,
})
