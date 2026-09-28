local t = require('telescope.builtin')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

-- "estudar um commit" sem sair do layout normal: escolhe o commit
-- e os trechos que ele mexeu viram o quickfix (]q/[q anda entre
-- eles). Dois modos, alternados com <leader>gv:
--   real   -> abre os arquivos de verdade (editaveis) e os sinais do
--             gitsigns passam a comparar com o pai do commit
--   commit -> abre o arquivo COMO ESTAVA naquele commit, somente
--             leitura, com o que ele adicionou realcado e o que
--             ele apagou em linhas virtuais
-- ]h / [h pulam entre os trechos do mesmo arquivo, ]g / [g entre
-- commits e <leader>gq encerra o estudo.
-- shas: commits do ultimo <leader>gl, do mais antigo pro mais novo,
-- e i o que esta sendo estudado: e o que ]g / [g percorrem
local estudo = { shas = {}, i = 0, sha = nil, modo = 'real' }
local ns_commit = vim.api.nvim_create_namespace('estudo_commit')

-- um arquivo do diff: { path, hunks = { { old, new, count, del = {linhas} } } }
local function ler_diff(sha)
    local diff = vim.fn.systemlist({ 'git', 'show', '--format=', '-U0', '--no-color', sha })
    local arquivos, atual, hunk = {}, nil, nil
    for _, l in ipairs(diff) do
        local path = l:match('^%+%+%+ b/(.+)$')
        if path then
            atual = { path = path, hunks = {} }
            table.insert(arquivos, atual)
        elseif l:match('^%+%+%+ /dev/null') then
            atual = nil   -- arquivo deletado pelo commit
        elseif atual then
            local ini, qtd = l:match('^@@ %-%S+ %+(%d+),?(%d*)')
            if ini then
                hunk = { new = tonumber(ini), count = qtd == '' and 1 or tonumber(qtd), del = {}, text = l }
                table.insert(atual.hunks, hunk)
            elseif hunk and l:sub(1, 1) == '-' and not l:match('^%-%-%- ') then
                table.insert(hunk.del, l:sub(2))
            end
        end
    end
    return arquivos
end

-- buffer somente leitura com o arquivo como estava no commit
local function buffer_do_commit(sha, arq)
    local nome = 'commit://' .. sha:sub(1, 7) .. '/' .. arq.path
    local buf = vim.fn.bufnr(nome)
    if buf ~= -1 then return buf end
    buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, nome)
    local linhas = vim.fn.systemlist({ 'git', 'show', sha .. ':' .. arq.path })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, linhas)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].filetype = vim.filetype.match({ filename = arq.path, buf = buf }) or ''
    -- o gitsigns nao anexa aqui, entao ]h / [h pulam entre os
    -- trechos deste commit, como fariam num arquivo normal
    local inicios = {}
    for _, h in ipairs(arq.hunks) do table.insert(inicios, math.max(h.new, 1)) end
    local function pular(passo)
        local cur = vim.fn.line('.')
        local alvo
        for _, l in ipairs(inicios) do
            if passo > 0 and l > cur and not alvo then alvo = l end
            if passo < 0 and l < cur then alvo = l end
        end
        if alvo then vim.api.nvim_win_set_cursor(0, { alvo, 0 }) end
    end
    vim.keymap.set('n', ']h', function() pular(1) end, { buffer = buf, desc = 'Proximo trecho do commit' })
    vim.keymap.set('n', '[h', function() pular(-1) end, { buffer = buf, desc = 'Trecho anterior do commit' })
    for _, h in ipairs(arq.hunks) do
        for r = h.new, h.new + h.count - 1 do
            vim.api.nvim_buf_set_extmark(buf, ns_commit, r - 1, 0, {
                line_hl_group = 'DiffAdd', sign_text = '+', sign_hl_group = 'GitSignsAdd',
            })
        end
        if #h.del > 0 then
            local virt = {}
            for _, d in ipairs(h.del) do table.insert(virt, { { d, 'DiffDelete' } }) end
            -- com count > 0 as apagadas foram trocadas pelas linhas
            -- a partir de h.new: vao em cima dela. Com count 0 foi
            -- so remocao, e elas vinham DEPOIS da linha h.new
            -- (h.new == 0: no topo do arquivo).
            local acima = h.count > 0 or h.new == 0
            local row = math.max(h.new - 1, 0)
            row = math.min(row, math.max(#linhas - 1, 0))
            vim.api.nvim_buf_set_extmark(buf, ns_commit, row, 0, {
                virt_lines = virt, virt_lines_above = acima,
            })
        end
    end
    return buf
end

local function limpar_buffers_de_commit()
    local function de_commit(b) return vim.api.nvim_buf_get_name(b):match('^commit://') end
    -- apagar um buffer fecha as janelas que mostram ele; troca o
    -- conteudo delas antes, para nao desmontar o layout
    local substituto
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if not substituto and vim.bo[b].buflisted and vim.bo[b].buftype == '' and not de_commit(b) then
            substituto = b
        end
    end
    for _, w in ipairs(vim.api.nvim_list_wins()) do
        if de_commit(vim.api.nvim_win_get_buf(w)) then
            vim.api.nvim_win_set_buf(w, substituto or vim.api.nvim_create_buf(true, false))
        end
    end
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if de_commit(b) then
            pcall(vim.api.nvim_buf_delete, b, { force = true })
        end
    end
end

local function estudar_commit(sha)
    estudo.sha = sha
    local root = vim.fn.systemlist({ 'git', 'rev-parse', '--show-toplevel' })[1]
    local itens = {}
    limpar_buffers_de_commit()
    for _, arq in ipairs(ler_diff(sha)) do
        local buf = estudo.modo == 'commit' and buffer_do_commit(sha, arq) or nil
        for _, h in ipairs(arq.hunks) do
            table.insert(itens, {
                bufnr = buf, filename = not buf and (root .. '/' .. arq.path) or nil,
                lnum = math.max(h.new, 1), text = h.text,
            })
        end
    end
    local titulo = vim.fn.system({ 'git', 'log', '-1', '--format=%h %s', sha }):gsub('\n', '')
    vim.fn.setqflist({}, ' ', { title = '[' .. estudo.modo .. '] ' .. titulo, items = itens })
    if estudo.modo == 'real' then
        require('gitsigns').change_base(sha .. '^', true)
    end
    if #itens > 0 then
        vim.cmd('cfirst')
        vim.cmd('botright copen 8')
        vim.cmd('wincmd p')
    end
    local pos = ''
    for i, s in ipairs(estudo.shas) do
        if vim.startswith(s, sha) or vim.startswith(sha, s) then
            estudo.i = i
            pos = ' [' .. i .. '/' .. #estudo.shas .. ']'
        end
    end
    vim.notify('Estudando' .. pos .. ' (' .. estudo.modo .. ') ' .. titulo .. ' (' .. #itens .. ' trechos)')
end

-- alterna entre ver os arquivos reais e a versao do commit
vim.keymap.set('n', '<leader>gv', function()
    estudo.modo = estudo.modo == 'real' and 'commit' or 'real'
    if estudo.sha then
        estudar_commit(estudo.sha)
    else
        vim.notify('Modo de estudo: ' .. estudo.modo)
    end
end, { desc = 'Estudo: arquivo real <-> versao do commit' })

-- ]g: proximo commit (mais novo) · [g: anterior (mais antigo)
local function pular_commit(passo)
    local alvo = estudo.shas[estudo.i + passo]
    if not alvo then
        vim.notify(#estudo.shas == 0 and 'Nenhum commit em estudo: use <leader>gl'
            or 'Nao ha mais commits nessa direcao', vim.log.levels.WARN)
        return
    end
    estudar_commit(alvo)
end
vim.keymap.set('n', ']g', function() pular_commit(1) end, { desc = 'Proximo commit em estudo' })
vim.keymap.set('n', '[g', function() pular_commit(-1) end, { desc = 'Commit anterior em estudo' })

-- commits que so existem na branch atual: tudo que o HEAD alcanca, menos o
-- que qualquer OUTRA branch (local ou remota) tambem alcanca. Comparar so com
-- origin/master traz junto os commits de branches em que esta foi baseada e
-- que ainda nao entraram na master.
local function so_desta_branch()
    local atual = vim.fn.systemlist({ 'git', 'branch', '--show-current' })[1] or ''
    if atual == '' then
        return { 'origin/master..HEAD' }, 'origin/master..HEAD'   -- HEAD solto
    end
    local upstream = vim.fn.systemlist({ 'git', 'rev-parse', '--abbrev-ref', atual .. '@{upstream}' })[1] or ''
    local args = { 'HEAD', '--not', '--exclude=' .. atual, '--branches' }
    if vim.v.shell_error == 0 and upstream ~= '' then
        table.insert(args, '--exclude=' .. upstream)
    end
    table.insert(args, '--remotes')
    return args, atual
end

-- range: lista de argumentos do git log · titulo: o que aparece no picker
local function commits_para_estudar(range, titulo)
    t.git_commits({
        prompt_title = 'Estudar commit (' .. titulo .. ')',
        git_command = vim.list_extend({ 'git', 'log', '--pretty=oneline', '--abbrev-commit' }, range),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local sha = action_state.get_selected_entry().value
                actions.close(prompt_bufnr)
                estudo.shas = vim.fn.systemlist(vim.list_extend({ 'git', 'log', '--reverse', '--format=%H' }, range))
                estudar_commit(sha)
            end)
            return true
        end,
    })
end
-- commits so desta branch (o que ela tem a mais que a master)
vim.keymap.set('n', '<leader>gl', function() commits_para_estudar(so_desta_branch()) end,
    { desc = 'Estudar commits da branch' })
vim.keymap.set('n', '<leader>gL', function() commits_para_estudar({ 'HEAD' }, 'todos') end,
    { desc = 'Estudar qualquer commit' })

-- sai do estudo: sinais de volta ao normal, quickfix fechado e os
-- buffers commit:// apagados
vim.keymap.set('n', '<leader>gq', function()
    require('gitsigns').reset_base(true)
    limpar_buffers_de_commit()
    vim.fn.setqflist({}, 'r', { title = '', items = {} })
    vim.cmd('cclose')
    estudo.shas, estudo.i, estudo.sha = {}, 0, nil
    vim.notify('Estudo encerrado')
end, { desc = 'Encerrar estudo de commits' })
