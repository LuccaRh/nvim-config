-- bootstrap do lazy.nvim (instala o gerenciador sozinho na 1ª vez)
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- cada arquivo em lua/plugins/ devolve a spec de um plugin
require('lazy').setup({
    spec = { { import = 'plugins' } },
})
