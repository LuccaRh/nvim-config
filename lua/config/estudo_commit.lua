local t = require('telescope.builtin')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

-- "estudar um commit" sem sair do layout normal: escolhe o commit
-- e os trechos que ele mexeu viram o quickfix (]q/[q anda entre
-- eles). Dois modos, alternados com <leader>gv:
--   real   -> abre os arquivos de verdade (editaveis) e marca com
--             um sinal proprio as linhas que vieram do commit (o +
--             do gitsigns continua sendo so o que nao foi commitado)
--   commit -> abre o arquivo COMO ESTAVA naquele commit, somente
--             leitura, com o que ele adicionou realcado e o que
--             ele apagou em linhas virtuais
-- ]h / [h pulam entre os trechos do mesmo arquivo, ]g / [g entre
-- commits e <leader>gq encerra o estudo.
-- shas: commits do ultimo <leader>gl, do mais antigo pro mais novo,
-- e i o que esta sendo estudado: e o que ]g / [g percorrem
local estudo = { shas = {}, i = 0, sha = nil, modo = 'real' }
local ns_commit = vim.api.nvim_create_namespace('estudo_commit')
local ns_real = vim.api.nvim_create_namespace('estudo_commit_real')
vim.api.nvim_set_hl(0, 'EstudoCommit', { link = 'DiagnosticInfo', default = true })

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

-- modo real: marca no arquivo de verdade as linhas que o blame ainda
-- atribui ao commit (as que commits posteriores ou mudancas nao
-- commitadas mexeram ja nao sao dele). O ]h / [h do gitsigns usa
-- b:estudo_trechos para pular entre esses blocos.
local function marcar_real(buf)
    if not estudo.arquivos or not vim.api.nvim_buf_is_loaded(buf) then return end
    local rel = estudo.arquivos[vim.api.nvim_buf_get_name(buf)]
    if not rel then return end
    vim.api.nvim_buf_clear_namespace(buf, ns_real, 0, -1)
    local conteudo = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n') .. '\n'
    local blame = vim.fn.systemlist({ 'git', '-C', estudo.root, 'blame', '-l', '-s', '--contents', '-', '--', rel }, conteudo)
    if vim.v.shell_error ~= 0 then return end
    local inicios, anterior = {}, false
    for i, l in ipairs(blame) do
        local do_commit = l:match('^%^?(%x+)') == estudo.sha
        if do_commit then
            vim.api.nvim_buf_set_extmark(buf, ns_real, i - 1, 0, {
                sign_text = '▍', sign_hl_group = 'EstudoCommit', priority = 5,
            })
            if not anterior then table.insert(inicios, i) end
        end
        anterior = do_commit
    end
    vim.b[buf].estudo_trechos = inicios
end

local function desmarcar_real()
    estudo.arquivos = nil
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) then
            vim.api.nvim_buf_clear_namespace(b, ns_real, 0, -1)
            vim.b[b].estudo_trechos = nil
        end
    end
end

-- arquivos abertos depois (pelo quickfix) tambem recebem as marcas
vim.api.nvim_create_autocmd('BufReadPost', {
    group = vim.api.nvim_create_augroup('EstudoCommitReal', { clear = true }),
    callback = function(ev) marcar_real(ev.buf) end,
})

-- realce do gitsigns no proprio arquivo: linhas novas/mudadas com fundo,
-- palavras mudadas e o que foi apagado em linhas virtuais
local function realce_unstaged(ligado)
    local gs = require('gitsigns')
    gs.toggle_linehl(ligado)
    gs.toggle_word_diff(ligado)
    gs.toggle_deleted(ligado)
    estudo.unstaged = ligado
end

local function estudar_commit(sha)
    estudo.sha = vim.fn.systemlist({ 'git', 'rev-parse', sha })[1]
    sha = estudo.sha
    local root = vim.fn.systemlist({ 'git', 'rev-parse', '--show-toplevel' })[1]
    local itens = {}
    limpar_buffers_de_commit()
    desmarcar_real()
    if estudo.unstaged then realce_unstaged(false) end
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
        estudo.root, estudo.arquivos = root, {}
        for _, arq in ipairs(ler_diff(sha)) do
            estudo.arquivos[root .. '/' .. arq.path] = arq.path
        end
        for _, b in ipairs(vim.api.nvim_list_bufs()) do marcar_real(b) end
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

local function eh_ancestral(a, b)
    vim.fn.system({ 'git', 'merge-base', '--is-ancestor', a, b })
    return vim.v.shell_error == 0
end

-- de onde a branch saiu, pelo reflog dela: o ponto em que foi criada,
-- movido por rebase/reset que a levaram pra fora da propria historia.
-- Um rebase -i ou reset pra tras (alvo ancestral da ponta de antes) nao
-- muda a base, e voltar pra uma ponta que a branch ja teve (desfazer um
-- rebase com reset) volta a base daquela epoca. nil se o reflog nao
-- conta a historia toda.
local function base_pelo_reflog(branch)
    local log = vim.fn.systemlist({ 'git', 'reflog', 'show', '--format=%H%x09%gs', 'refs/heads/' .. branch })
    if vim.v.shell_error ~= 0 or #log == 0 then return nil end
    local base, ponta
    local base_da_ponta = {}
    for i = #log, 1, -1 do   -- do mais antigo pro mais novo
        local sha, msg = log[i]:match('^(%x+)\t(.*)$')
        if not sha then return nil end
        if i == #log then
            local origem = msg:match('^branch: Created from (.+)$')
            -- sem registro da criacao (reflog expirou), ou copia local de
            -- uma branch remota: os commits dela nao nasceram aqui
            if not origem or origem:match('^[^/]+/(.+)$') == branch then return nil end
            base = sha
        elseif base_da_ponta[sha] then
            base = base_da_ponta[sha]
        else
            local alvo
            if msg:match('^rebase[^:]*%(finish%)') or msg:match('^pull %-%-rebase[^:]*%(finish%)') then
                alvo = msg:match('onto (%x+)$')
            elseif msg:match('^reset: ') then
                alvo = sha
            end
            if alvo and not eh_ancestral(alvo, ponta) then base = alvo end
        end
        base_da_ponta[sha] = base
        ponta = sha
    end
    if not eh_ancestral(base, 'HEAD') then return nil end
    return base
end

-- commits criados na branch atual: do ponto de onde ela saiu ate o HEAD,
-- so pela linha dela (--first-parent: um merge da master nao traz os
-- commits de la). Sem reflog, cai pra tudo que o HEAD alcanca menos o que
-- outra branch tambem alcanca, ignorando as que foram criadas em cima
-- desta (elas tem todos os commits dela).
local function so_desta_branch()
    local atual = vim.fn.systemlist({ 'git', 'branch', '--show-current' })[1] or ''
    if atual == '' then
        return { 'origin/master..HEAD' }, 'origin/master..HEAD'   -- HEAD solto
    end
    local base = base_pelo_reflog(atual)
    if base and base ~= vim.fn.systemlist({ 'git', 'rev-parse', 'HEAD' })[1] then
        return { '--first-parent', base .. '..HEAD' }, atual .. ' desde ' .. base:sub(1, 7)
    end
    local upstream = vim.fn.systemlist({ 'git', 'rev-parse', '--symbolic-full-name', atual .. '@{upstream}' })[1] or ''
    local em_cima = {}
    for _, r in ipairs(vim.fn.systemlist({ 'git', 'for-each-ref', '--contains', 'HEAD', '--format=%(refname)' })) do
        em_cima[r] = true
    end
    local args = { 'HEAD', '--not' }
    for _, r in ipairs(vim.fn.systemlist({ 'git', 'for-each-ref', '--format=%(refname)', 'refs/heads', 'refs/remotes' })) do
        if not em_cima[r] and r ~= upstream and not r:match('/HEAD$') then
            table.insert(args, r)
        end
    end
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

local function encerrar_estudo()
    desmarcar_real()
    limpar_buffers_de_commit()
    realce_unstaged(false)
    vim.fn.setqflist({}, 'r', { title = '', items = {} })
    vim.cmd('cclose')
    estudo.shas, estudo.i, estudo.sha = {}, 0, nil
end

-- o que ainda nao foi para o stage, no mesmo esquema do estudo: os
-- trechos de todos os arquivos no quickfix e os arquivos reais com o
-- realce do modo commit. De novo (ou <leader>gq) desliga.
vim.keymap.set('n', '<leader>gu', function()
    if estudo.unstaged then
        encerrar_estudo()
        vim.notify('Mudancas unstaged: realce desligado')
        return
    end
    encerrar_estudo()
    realce_unstaged(true)
    require('gitsigns').setqflist('all', { open = false }, function()
        vim.schedule(function()
            local n = #vim.fn.getqflist()
            if n == 0 then
                vim.notify('Nenhuma mudanca unstaged')
                return
            end
            vim.fn.setqflist({}, 'a', { title = '[unstaged]' })
            vim.cmd('cfirst')
            vim.cmd('botright copen 8')
            vim.cmd('wincmd p')
            vim.notify('Mudancas unstaged (' .. n .. ' trechos)')
        end)
    end)
end, { desc = 'Ver mudancas unstaged' })

-- sai do estudo: marcas do commit e realce removidos, quickfix fechado
-- e os buffers commit:// apagados
vim.keymap.set('n', '<leader>gq', function()
    encerrar_estudo()
    vim.notify('Estudo encerrado')
end, { desc = 'Encerrar estudo de commits' })
