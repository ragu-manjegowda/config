lua <<EOF
  local cmp = require('cmp')
  local lspkind = require('lspkind')
  cmp.setup {
    -- You must set mapping if you want.
    mapping = {
      ['<C-p>'] = cmp.mapping.select_prev_item(),
      ['<C-n>'] = cmp.mapping.select_next_item(),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.close(),
      ['<CR>'] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Insert,
        select = true,
      })
    },

    -- You should specify your *installed* sources.
    sources = {
      { name = 'nvim_lsp' },
      { name = 'path' },
      { name = 'treesitter' },
      { name = 'buffer' },
    },

    completion = {
      completeopt = 'menu,menuone,noinsert',
      documentation = {}
    },

    formatting = {
      format = function(entry, vim_item)
      vim_item.kind = lspkind.presets.default[vim_item.kind] .. ' ' .. vim_item.kind
      vim_item.menu = ({
        ultisnips = '[Ultisnips]',
        nvim_lsp = '[LSP]',
        path = '[Path]',
        treesitter = '[Treesitter]',
        buffer = '[Buffer]',
        calc = '[Calc]',
      })[entry.source.name]

      return vim_item
      end
    }
  }

EOF

" Setup buffer configuration (nvim-lua source only enables in Lua filetype).
autocmd FileType lua lua require'cmp'.setup.buffer {
\   sources = {
\     { name = 'buffer' },
\     { name = 'nvim_lua' },
\   },
\ }
