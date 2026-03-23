vim.o.number = true
vim.o.relativenumber = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.confirm = true
vim.o.undofile = true
vim.o.cursorline = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.signcolumn = 'yes'
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.o.breakindent = true
vim.o.splitkeep = 'screen'
-- vim.o.wrap = false
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- unify nvim and system clipboard
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

-- diagnostic configurations
vim.diagnostic.config {
  -- have virtual text handler disabled by default and enable it with a keymap
  virtual_text = false,
  signs = {
    numhl = { -- colorize line numbers of lines with diagnostics
      [vim.diagnostic.severity.ERROR] = 'DiagnosticError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticWarn',
      [vim.diagnostic.severity.HINT] = 'DiagnosticHint',
      [vim.diagnostic.severity.INFO] = 'DiagnosticInfo',
    },
  },
  severity_sort = true,
}

vim.keymap.set('n', 'gK', function()
  local new_config = not vim.diagnostic.config().virtual_text
  vim.diagnostic.config { virtual_text = new_config }
end, { desc = 'Toggle diagnostics virtual text' })

-- autocmds
--[[ Remember to define PackChanged autocmds before running any vim.pack
transaction that is supposed to be the trigger ]]
--

-- highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

local tabs_group = vim.api.nvim_create_augroup('configure-tabs', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = tabs_group,
  pattern = { 'lua', 'sh', 'markdown' },
  desc = 'Set tabs to 2 spaces',
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = tabs_group,
  pattern = { 'c' },
  desc = 'Use tabs instead of spaces for C files',
  callback = function()
    vim.o.shiftwidth = 8
    vim.o.tabstop = 8
    vim.o.softtabstop = 8
    vim.o.expandtab = false
  end,
})

-- enable spell check
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('configure-spellcheck', { clear = true }),
  pattern = { 'markdown', 'gitcommit' },
  desc = 'Enable spellcheck',
  callback = function()
    vim.opt_local.spelllang = { 'en_us', 'es_mx' }
    vim.o.spell = true
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  -- FileType matches against buffer filetype, not buffer name
  pattern = { 'lua', 'sh', 'c', 'python' },
  desc = 'Use treesitter as fold provider',
  callback = function()
    -- TODO: add check to verify that the language has fold capabilities
    if package.loaded['nvim-treesitter'] then
      vim.treesitter.start()
      -- By default fold options target current buffer only
      vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.o.foldmethod = 'expr'
      -- Avoid folds starting closed
      vim.o.foldlevel = 99
    end
  end,
})

vim.api.nvim_create_autocmd('BufWinLeave', {
  desc = 'Save view when leaving a buffer',
  callback = function(ev)
    local buf = ev.buf
    if
      --[[Check for appropiate buffers:
      valid buffer: the buffer is in the buffer list
      non-empty name: the buffer name isn't an empty string
      empty type: only non-modifiable buffers like help buffers have types ]]
      --
      vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_buf_get_name(buf) ~= ''
      and vim.api.nvim_get_option_value('buftype', { buf = buf }) == ''
    then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd 'silent! mkview'
      end)
    end
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  desc = 'Load view when entering a buffer',
  callback = function(ev)
    local buf = ev.buf
    if
      vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_buf_get_name(buf) ~= ''
      and vim.api.nvim_get_option_value('buftype', { buf = buf }) == ''
    then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd 'silent! loadview'
      end)
    end
  end,
})

vim.api.nvim_create_autocmd('PackChanged', {
  desc = 'Handle nvim-treesitter updates',
  group = vim.api.nvim_create_augroup('nvim-treesitter-pack-changed-update-handler', { clear = true }),
  callback = function(event)
    if event.data.kind == 'update' and event.data.spec.name == 'nvim-treesitter' then
      vim.notify('nvim-treesitter updated, running TSUpdate...', vim.log.levels.INFO)
      -- TODO: Add check for onstalling nvim-treesitter-cli
      local ok = pcall(function()
        -- run TSUpdate after updating nvim-treesitter as recomended by treesitter wiki
        vim.cmd 'TSUpdate'
      end)
      if ok then
        vim.notify('TSUpdate completed successfully!', vim.log.levels.INFO)
      else
        vim.notify('TSUpdate command not available yet, skipping', vim.log.levels.WARN)
      end
    end
  end,
})

local lps_autocmds = vim.api.nvim_create_augroup('lps_autocmds ', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', {
  group = lps_autocmds,
  desc = 'Define lsp keymaps',
  callback = function(ev)
    vim.keymap.set('n', 'gd', function()
      vim.lsp.buf.definition()
    end, { buffer = ev.buf, desc = 'Go to definition' })
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = lps_autocmds,
  desc = 'Define Texlab specific keymaps',
  pattern = '*.tex',
  callback = function(ev)
    local client_id = ev.data.client_id
    local client = vim.lsp.get_client_by_id(client_id)
    if not client or client.name ~= 'texlab' then
      return
    end

    vim.keymap.set('n', '<localleader>f', function()
      vim.lsp.buf_request(
        0, -- 0 for current buffer
        --- texlab extended methods produce type-mismatch
        ---@diagnostic disable-next-line: param-type-mismatch
        'textDocument/forwardSearch',
        -- 0 for making position parameters of current window
        vim.lsp.util.make_position_params(0, client.offset_encoding),
        function(err, result)
          if err then
            vim.notify('Forward search error: ' .. err.message, vim.log.levels.ERROR)
          elseif result and result.status ~= 0 then
            vim.notify('Forward search failed with status: ' .. result.status, vim.log.levels.WARN)
          end
        end
      )
    end, { buffer = true, desc = 'TexLab: Forward Search' })

    vim.keymap.set('n', '<localleader>b', function()
      if vim.fn.executable 'tectonic' ~= 1 then
        vim.notify('Build can\'t be started, missing dependency: tectonic', vim.log.levels.WARN)
        return
      end
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.lsp.buf_request(0, 'textDocument/build', {
        textDocument = vim.lsp.util.make_text_document_params(0),
      }, function(err, result)
        if err then
          vim.notify('Build error: ' .. err.message, vim.log.levels.ERROR)
        elseif result and result.status ~= 0 then
          vim.notify('Build failed', vim.log.levels.WARN)
        else
          vim.notify('Build succeeded', vim.log.levels.INFO)
        end
      end)
    end, { buffer = true, desc = 'TexLab: Build' })
  end,
})

local linter_autocmds = vim.api.nvim_create_augroup('lint', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*.lua',
  group = linter_autocmds,
  desc = 'Make selene (lua linter) detect project root',
  callback = function(ev)
    if package.loaded['lint'] then
      local selene = require('lint').linters.selene
      selene.args = {
        '--config',
        vim.fn.expand(ev.file),
        '--display-style',
        'json',
        '-',
      }
    end
  end,
})

vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
  desc = 'Trigger linting after writing a buffer',
  group = linter_autocmds,
  callback = function()
    -- try_lint without arguments runs the linters defined in `linters_by_ft` for
    -- the current filetype
    require('lint').try_lint()
  end,
})

-- packages installation
if vim.fn.executable 'git' == 1 then
  vim.pack.add {
    -- { src = 'https://github.com/rose-pine/neovim', name = 'rose-pine' },
    { src = 'https://github.com/vague-theme/vague.nvim' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
    { src = 'https://github.com/mason-org/mason.nvim.git' },
    { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim.git' },
    { src = 'https://github.com/mfussenegger/nvim-lint.git' },
    { src = 'https://github.com/stevearc/conform.nvim.git' },
    { src = 'https://github.com/folke/lazydev.nvim.git' },
    { src = 'https://github.com/ibhagwan/fzf-lua.git' },
  }
else
  vim.notify('Unable to install plugins, no git binary found', vim.log.levels.WARN)
end

-- set colorscheme to rose-pine
-- local status, err = pcall(vim.cmd.colorscheme, 'rose-pine')
-- if not status then
--   vim.notify('Unable to set colorscheme: ' .. err, vim.log.levels.ERROR)
-- end

-- colorscheme based on rose-pine under tmux without 256-colors enabled
require('vague').setup {
  colors = {
    bg = '#000000',
  },
}

vim.cmd 'colorscheme vague'

-- install default treesitter parsers
require('nvim-treesitter').install { 'lua', 'bash', 'c', 'python', 'markdown', 'vimdoc' }

-- require Mason
require('mason').setup()

-- install tools through mason-tool-installer
require('mason-tool-installer').setup {
  ensure_installed = {
    'bash-language-server',
    'shellcheck',
    'shfmt',
    'clangd',
    'clang-format',
    'marksman',
    'mdslw',
    'mdsf',
    {
      'markdownlint-cli2',
      condition = function()
        return vim.fn.executable 'npm' == 1
      end,
    }, -- depends on npm for installation
    'stylua',
    'lua-language-server',
    'selene',
    'texlab', -- depends on tectonic for compilation of tex files
  },
}

-- nvim-lint
require('lint').linters_by_ft = {
  markdown = { 'markdownlint-cli2' },
  sh = { 'shellcheck' },
  lua = { 'selene' },
}

local function should_ignore_clang_format(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local format_dir = vim.fn.fnamemodify(filepath, ':h')
  -- findfile returns relative path
  local ignore_file = vim.fn.findfile('.clang-format-ignore', format_dir .. ';')

  if ignore_file == '' or type(ignore_file) ~= 'string' then
    return false
  end

  -- resolve ignore_file to an absolute path
  ignore_file = vim.fn.fnamemodify(ignore_file, ':p')

  local ignore_dir = vim.fn.fnamemodify(ignore_file, ':h')
  local file = io.open(ignore_file, 'r')
  if not file then
    return false
  end

  local content = file:read '*a'
  file:close()

  -- Build the path of the file relative to the ignore file's directory
  -- so that patterns like "src/*.cpp" can be matched correctly
  if filepath:sub(1, #ignore_dir) ~= ignore_dir then
    return false -- file is not under the ignore file's directory
  end
  local rel_path = filepath:sub(#ignore_dir + 2) -- strip leading "ignore_dir/"

  -- Convert a glob pattern into a Lua pattern:
  --   '.' '+' '-' '^' '$' '(' ')' '[' ']' '%' are escaped
  --   '*' becomes '[^/]*'  (never crosses a directory boundary)
  local function glob_to_lua(glob)
    local result = glob:gsub('([%.%+%-%^%$%(%)%[%]%%])', '%%%1')
    result = result:gsub('%*', '[^/]*')
    return result
  end

  -- Returns true when rel_path is covered by pattern.
  -- A trailing '/' means "this directory and everything inside it".
  local function path_matches(path, pattern)
    if pattern:sub(1, 2) == './' then
      pattern = pattern:sub(3)
    end

    if pattern:sub(-1) == '/' then
      -- Match the directory itself or anything beneath it
      local lua_pat = '^' .. glob_to_lua(pattern)
      return path:match(lua_pat) ~= nil
    else
      local lua_pat = '^' .. glob_to_lua(pattern) .. '$'
      return path:match(lua_pat) ~= nil
    end
  end

  -- Process every pattern in order; last match wins (same as gitignore semantics).
  -- A leading '!' negates the pattern: if it matches, the file is un-ignored.
  local ignored = false

  for line in content:gmatch '[^\r\n]+' do
    line = line:match '^%s*(.-)%s*$' -- trim surrounding whitespace

    -- Skip empty lines and comment lines
    if line ~= '' and line:sub(1, 1) ~= '#' then
      local negate = false
      local pattern = line

      if pattern:sub(1, 1) == '!' then
        negate = true
        pattern = pattern:sub(2)
      end

      if path_matches(rel_path, pattern) then
        ignored = not negate
      end
    end
  end

  return ignored
end

-- conform-nvim
require('conform').setup {
  formatters_by_ft = {
    c = { 'clang-format' },
    sh = { 'shfmt' },
    lua = { 'stylua' },
    markdown = { 'mdsf', 'mdslw' },
  },
  -- shortcut to the autocmd to call format on save
  -- These options will be passed to conform.format()
  format_on_save = function(bufnr)
    if should_ignore_clang_format(bufnr) then
      return { dry_run = true }
    else
      return {
        timeout_ms = 500,
        lsp_format = 'fallback',
      }
    end
  end,
  formatters = {
    shfmt = {
      append_args = { '-i', '2' },
    },
    mdsf = {
      -- use global configuration file for markdwon blocks formatter
      append_args = {
        '--config',
        vim.fn.expand '~/.config/mdsf/mdsf.json',
      },
    },
    stylua = {
      append_args = {
        '--indent-type',
        'Spaces',
        '--indent-width',
        '2',
        '--quote-style',
        'ForceSingle',
        '--call-parentheses',
        'None',
      },
    },
    clang_format = {},
  },
}

-- enable lsp servers configured in ~/.config/nvim/lsp
vim.lsp.enable 'clangd'
vim.lsp.enable 'marksman'
vim.lsp.enable 'texlab'
-- for use with lazydev, lua-language-server config has to be named lua_ls
-- https://github.com/folke/lazydev.nvim/discussions/28
vim.lsp.enable 'lua_ls'
require('lazydev').setup()
vim.lsp.enable 'bashls'

vim.g.mapleader = ' '
if vim.fn.executable 'fzf' == 1 then
  vim.keymap.set('n', '<leader><leader>', function()
    require('fzf-lua').files()
  end, { desc = 'Search files' })
else
  vim.notify('Unable to setup fzf-lua, missing fzf binary', vim.log.levels.WARN)
end
