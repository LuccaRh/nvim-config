-- pular para qualquer ponto da tela: s + 2 letras
return {
    'folke/flash.nvim',
    event = 'VeryLazy',
    keys = {{
        's',
        mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash' },
    },
}
