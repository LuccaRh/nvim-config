-- linha fina na coluna 80, em vez do bloco solido do ColorColumn
return {
    'lukas-reineke/virt-column.nvim',
    event = 'VeryLazy',
    opts = {
        char = '│',
        highlight = 'VirtColumn',
    },
}
