# nvim-config

Minha config do Neovim, em Lua, com [lazy.nvim](https://github.com/folke/lazy.nvim).
`<leader>` = **espaço**.

## Instalação

```sh
git clone git@github.com:LuccaRh/nvim-config.git ~/.config/nvim
nvim   # o lazy.nvim se instala sozinho e baixa os plugins
```

Precisa de: Neovim 0.11+, `git`, `make` e um compilador C (telescope-fzf-native e
treesitter), `ripgrep` (grep do telescope), `lazygit` e uma Nerd Font.

## Estrutura

```
init.lua          só carrega os módulos de lua/config/
lua/config/       o que não é plugin: options, keymaps, diagnostics, autocmds,
                  lazy (bootstrap) e estudo_commit
lua/plugins/      um arquivo por plugin, cada um devolve a spec dele
```

Plugin novo = arquivo novo em `lua/plugins/` com `return { 'autor/plugin', ... }`.

## Plugins

| Plugin | Para quê |
|---|---|
| cyberdream + virt-column | tema transparente e linha fina na coluna 80 |
| treesitter | highlight e indentação |
| telescope (+ fzf-native) | busca de arquivos, texto, buffers, símbolos |
| mason + nvim-lspconfig | LSP: `basedpyright` (Python) e `vtsls` (TypeScript) |
| blink.cmp | autocomplete (preset *super-tab*) |
| gitsigns | mudanças na coluna e blame da linha do cursor |
| lazygit | cliente git dentro do nvim |
| diffview | diff lado a lado e histórico de commits |
| neo-tree | árvore de arquivos |
| flash | pular para qualquer ponto da tela |
| vim-illuminate | realça as ocorrências da palavra sob o cursor |
| vim-visual-multi | múltiplos cursores |

## Atalhos

### Geral

| Tecla | Ação |
|---|---|
| `Ctrl-h/j/k/l` | pula entre janelas |
| `Shift-h` / `Shift-l` | buffer anterior / próximo |
| `Esc` | limpa o realce da busca |
| `s` + 2 letras | flash: pula para o ponto na tela |
| `<leader>e` | abre/fecha o neo-tree |
| `Ctrl-n` | multi-cursor na palavra (de novo = próxima ocorrência) |

### Busca (telescope)

| Tecla | Ação |
|---|---|
| `<leader>ff` · `<leader>fg` | arquivo por nome · grep no projeto |
| `<leader>fb` | buffers (`Ctrl-d`/`d` fecha, `Alt-d`/`D` fecha descartando) |
| `<leader>fs` | símbolos do projeto |
| `<leader>fd` / `<leader>fD` | erros do arquivo / do projeto |

Dentro do picker: `Ctrl-v`/`Ctrl-x` abrem em split, `Ctrl-q` manda pro quickfix.

### LSP

| Tecla | Ação |
|---|---|
| `gd` | definição na janela atual |
| `gD` / `gS` | definição em split vertical / horizontal |
| `Ctrl+clique` / `Ctrl+Shift+clique` | definição / definição em split |
| `gy` · `gi` · `gr` | tipo · implementações · referências |
| `K` | hover |
| `<leader>rn` · `<leader>ca` | renomear · ações de código |
| `Ctrl-o` / `Ctrl-i` | volta / avança (botões do mouse também) |

### Diagnósticos

O erro aparece sozinho embaixo da linha do cursor.

| Tecla | Ação |
|---|---|
| `]e` / `[e` | próximo / anterior erro |
| `<leader>dd` | popup com o erro da linha |
| `<leader>dv` | alterna: só a linha do cursor ↔ o arquivo todo |
| `<leader>dl` | diagnósticos no loclist |

### Git

| Tecla | Ação |
|---|---|
| `]h` / `[h` | próxima / anterior mudança do arquivo |
| `<leader>gg` | lazygit (`e` lá dentro abre o arquivo neste nvim) |
| `<leader>gd` | diffview do que não foi commitado (staged e unstaged) |
| `<leader>gh` / `<leader>gH` | histórico do arquivo / da branch no diffview |
| `<leader>gc` | fecha o diffview |
| `<leader>gl` / `<leader>gL` | estudar commits da branch / de qualquer commit |

**Estudar commits:** `<leader>gl` abre os commits criados na branch atual (pelo reflog dela); `Enter`
num commit põe os trechos dele no quickfix.

| Tecla | Ação |
|---|---|
| `]q` / `[q` | próximo / anterior trecho |
| `]g` / `[g` | próximo / anterior commit |
| `<leader>gv` | alterna entre arquivo real (editável, com LSP, linhas do commit marcadas com `▍`) e versão do commit |
| `<leader>gu` | mudanças unstaged no quickfix, com linhas realçadas e apagadas em vermelho (de novo desliga) |
| `<leader>gq` | encerra o estudo |

## Comportamentos

- **Autosave** ao sair do insert, trocar de buffer ou perder o foco.
- **Trim** de espaços no fim das linhas ao salvar, exceto em markdown, diff e gitcommit.
- Undo persistente, busca com `smartcase`, preview ao vivo do `:%s`, splits abrem
  à direita/embaixo, clipboard do sistema, tabs = 4 espaços.
