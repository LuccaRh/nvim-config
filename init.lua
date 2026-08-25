-- ~/.config/nvim/init.lua
--
-- lua/config/   o que nao e plugin: opcoes, atalhos, autocmds
-- lua/plugins/  um arquivo por plugin (o lazy.nvim importa todos sozinho)

require('config.options')      -- leader e opcoes (precisa vir antes dos plugins)
require('config.diagnostics')  -- como os erros do LSP aparecem
require('config.autocmds')     -- autosave e trim ao salvar
require('config.lazy')         -- instala o lazy.nvim e carrega lua/plugins/
