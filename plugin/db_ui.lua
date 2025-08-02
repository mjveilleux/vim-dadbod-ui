-- Prevent loading multiple times
if vim.g.loaded_db_ui_lua then
  return
end
vim.g.loaded_db_ui_lua = true

-- Load the main module
local db_ui = require('db_ui')
local config = require('db_ui.config')

-- Set up autocommands for dbout files
local augroup = vim.api.nvim_create_augroup('db_ui_lua', { clear = true })

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = augroup,
  pattern = '*.dbout',
  callback = function()
    vim.bo.filetype = 'dbout'
  end
})

vim.api.nvim_create_autocmd('BufReadPost', {
  group = augroup,
  pattern = '*.dbout',
  callback = function()
    -- TODO: Implement dbout saving in Lua
    -- For now, just set filetype
    vim.bo.filetype = 'dbout'
  end
})

vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'dbout',
  callback = function()
    -- TODO: Implement dbout folding in Lua
    -- For now, use basic folding
    vim.opt_local.foldmethod = 'indent'
    vim.cmd('silent! normal!zo')
  end
})

vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  group = augroup,
  pattern = '*',
  callback = function()
    if vim.bo.filetype == 'dbout' or vim.bo.filetype == 'dbui' then
      vim.cmd('stopinsert')
    end
  end
})

-- Define user commands
vim.api.nvim_create_user_command('DBUI', function(opts)
  db_ui.open(opts.mods)
end, { desc = 'Open DBUI drawer' })

vim.api.nvim_create_user_command('DBUIToggle', function()
  db_ui.toggle()
end, { desc = 'Toggle DBUI drawer' })

vim.api.nvim_create_user_command('DBUIClose', function()
  db_ui.close()
end, { desc = 'Close DBUI drawer' })

vim.api.nvim_create_user_command('DBUIAddConnection', function()
  local connections = require('db_ui.connections')
  connections:new():add()
end, { desc = 'Add a new database connection' })

vim.api.nvim_create_user_command('DBUIFindBuffer', function()
  db_ui.find_buffer()
end, { desc = 'Find current buffer in DBUI' })

vim.api.nvim_create_user_command('DBUIRenameBuffer', function()
  -- This will be implemented
  vim.notify('DBUIRenameBuffer not yet implemented', vim.log.levels.WARN)
end, { desc = 'Rename current buffer' })

vim.api.nvim_create_user_command('DBUILastQueryInfo', function()
  -- This will be implemented
  vim.notify('DBUILastQueryInfo not yet implemented', vim.log.levels.WARN)
end, { desc = 'Show last query information' })

-- Define <Plug> mappings for DBUI functionality
local function setup_dbui_plugs()
  local db_ui = require('db_ui')
  
  vim.keymap.set('n', '<Plug>(DBUI_SelectLine)', function()
    db_ui.toggle_line()
  end, { desc = 'DBUI: Select line' })
  
  vim.keymap.set('n', '<Plug>(DBUI_SelectLineVsplit)', function()
    db_ui.toggle_line('vsplit')
  end, { desc = 'DBUI: Select line (vertical split)' })
  
  vim.keymap.set('n', '<Plug>(DBUI_Redraw)', function()
    db_ui.redraw()
  end, { desc = 'DBUI: Redraw' })
  
  vim.keymap.set('n', '<Plug>(DBUI_DeleteLine)', function()
    db_ui.delete_line()
  end, { desc = 'DBUI: Delete line' })
  
  vim.keymap.set('n', '<Plug>(DBUI_AddConnection)', function()
    db_ui.add_connection()
  end, { desc = 'DBUI: Add connection' })
  
  vim.keymap.set('n', '<Plug>(DBUI_ToggleDetails)', function()
    db_ui.toggle_details()
  end, { desc = 'DBUI: Toggle details' })
  
  vim.keymap.set('n', '<Plug>(DBUI_RenameLine)', function()
    vim.notify('Rename functionality not yet implemented', vim.log.levels.WARN)
  end, { desc = 'DBUI: Rename line' })
  
  vim.keymap.set('n', '<Plug>(DBUI_Quit)', function()
    db_ui.quit()
  end, { desc = 'DBUI: Quit' })
  
  vim.keymap.set('n', '<Plug>(DBUI_GotoFirstSibling)', function()
    db_ui.goto_sibling('first')
  end, { desc = 'DBUI: Go to first sibling' })
  
  vim.keymap.set('n', '<Plug>(DBUI_GotoLastSibling)', function()
    db_ui.goto_sibling('last')
  end, { desc = 'DBUI: Go to last sibling' })
  
  vim.keymap.set('n', '<Plug>(DBUI_GotoParentNode)', function()
    db_ui.goto_parent()
  end, { desc = 'DBUI: Go to parent node' })
  
  vim.keymap.set('n', '<Plug>(DBUI_GotoChildNode)', function()
    db_ui.goto_child()
  end, { desc = 'DBUI: Go to child node' })
  
  vim.keymap.set('n', '<Plug>(DBUI_GotoPrevSibling)', function()
    db_ui.goto_sibling('prev')
  end, { desc = 'DBUI: Go to previous sibling' })
  
  vim.keymap.set('n', '<Plug>(DBUI_GotoNextSibling)', function()
    db_ui.goto_sibling('next')
  end, { desc = 'DBUI: Go to next sibling' })
end

-- Define <Plug> mappings for SQL buffers
local function setup_sql_plugs()
  vim.keymap.set('n', '<Plug>(DBUI_SaveQuery)', function()
    local query = require('db_ui.query'):new()
    query:save_file()
  end, { desc = 'DBUI: Save query' })
  
  vim.keymap.set('n', '<Plug>(DBUI_EditBindParameters)', function()
    local query = require('db_ui.query'):new()
    query:edit_bind_parameters()
  end, { desc = 'DBUI: Edit bind parameters' })
  
  vim.keymap.set({'n', 'v'}, '<Plug>(DBUI_ExecuteQuery)', function()
    local query = require('db_ui.query'):new()
    query:execute_query()
  end, { desc = 'DBUI: Execute query' })
end

-- Setup <Plug> mappings immediately
setup_dbui_plugs()
setup_sql_plugs()

-- Load filetype plugins if not disabled
if not config.disable_mappings and not config.disable_mappings_dbui then
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'dbui',
    callback = function()
      local utils = require('db_ui.utils')
      utils.set_mapping({ 'o', '<CR>', '<2-LeftMouse>' }, '<Plug>(DBUI_SelectLine)')
      utils.set_mapping('S', '<Plug>(DBUI_SelectLineVsplit)')
      utils.set_mapping('R', '<Plug>(DBUI_Redraw)')
      utils.set_mapping('d', '<Plug>(DBUI_DeleteLine)')
      utils.set_mapping('A', '<Plug>(DBUI_AddConnection)')
      utils.set_mapping('H', '<Plug>(DBUI_ToggleDetails)')
      utils.set_mapping('r', '<Plug>(DBUI_RenameLine)')
      utils.set_mapping('q', '<Plug>(DBUI_Quit)')
      utils.set_mapping('<c-k>', '<Plug>(DBUI_GotoFirstSibling)')
      utils.set_mapping('<c-j>', '<Plug>(DBUI_GotoLastSibling)')
      utils.set_mapping('<C-p>', '<Plug>(DBUI_GotoParentNode)')
      utils.set_mapping('<C-n>', '<Plug>(DBUI_GotoChildNode)')
      utils.set_mapping('K', '<Plug>(DBUI_GotoPrevSibling)')
      utils.set_mapping('J', '<Plug>(DBUI_GotoNextSibling)')
    end
  })
end

if not config.disable_mappings and not config.disable_mappings_sql then
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'sql',
    callback = function()
      local utils = require('db_ui.utils')
      utils.set_mapping('<Leader>W', '<Plug>(DBUI_SaveQuery)')
      utils.set_mapping('<Leader>E', '<Plug>(DBUI_EditBindParameters)')
      utils.set_mapping('<Leader>S', '<Plug>(DBUI_ExecuteQuery)')
      utils.set_mapping('<Leader>S', '<Plug>(DBUI_ExecuteQuery)', 'v')
    end
  })
end

-- Setup with any existing configuration
config.setup()

-- Export icons to global variable for syntax highlighting
vim.g.db_ui_icons = config.icons

-- Export global Lua function for vim-dadbod-completion
-- Note: vim-dadbod-completion reads buffer variables directly, no autoload needed
_G.db_ui_get_conn_info = function(db_key_name)
  return require('db_ui').get_conn_info(db_key_name)
end 