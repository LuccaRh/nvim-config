-- diagnosticos (erros do LSP)
vim.diagnostic.config({
  -- mostra o erro embaixo da linha do cursor sozinho, sem apertar nada
  virtual_lines = { current_line = true },
  virtual_text = false,
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  float = { border = 'rounded', source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = 'E',
      [vim.diagnostic.severity.WARN]  = 'W',
      [vim.diagnostic.severity.INFO]  = 'I',
      [vim.diagnostic.severity.HINT]  = 'H',
    },
  },
})

-- ja existem por padrao: <C-w>d abre o float, ]d / [d pulam entre diagnosticos
vim.keymap.set('n', '<leader>dd', vim.diagnostic.open_float, { desc = 'Diagnostico da linha' })
vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, { desc = 'Diagnosticos no loclist' })
vim.keymap.set('n', ']e', function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { desc = 'Proximo erro' })
vim.keymap.set('n', '[e', function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { desc = 'Erro anterior' })

-- alterna entre "so a linha do cursor" e "todos os diagnosticos do arquivo"
vim.keymap.set('n', '<leader>dv', function()
  local cur = vim.diagnostic.config().virtual_lines
  local all = type(cur) == 'table' and cur.current_line == nil
  vim.diagnostic.config({ virtual_lines = all and { current_line = true } or true })
  vim.notify('virtual_lines: ' .. (all and 'linha atual' or 'arquivo todo'))
end, { desc = 'Alternar virtual_lines' })
