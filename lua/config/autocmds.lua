-- remover caraters branco das linhas
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  callback = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.api.nvim_win_set_cursor(0, pos)
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
