local config = require('db_ui.config')

local M = {}

-- Setup syntax highlighting for dbui buffers
function M.setup()
  local icons = config.icons
  
  -- Clear any existing syntax
  vim.cmd('syntax clear')
  
  -- Helper function to escape special regex characters
  local function escape_pattern(str)
    return vim.fn.escape(str, '*[]\\/.~^$')
  end
  
  -- Helper function to create syntax match
  local function create_syntax_match(name, pattern, link_to)
    vim.cmd(string.format('syn match %s /%s/', name, pattern))
    if link_to then
      vim.cmd(string.format('hi default link %s %s', name, link_to))
    end
  end
  
  -- Create syntax for expanded/collapsed icons
  if icons.expanded then
    for icon_name, icon_value in pairs(icons.expanded) do
      local syntax_name = 'dbui_expanded_' .. icon_name
      local pattern = '^[[:blank:]]*' .. escape_pattern(icon_value)
      create_syntax_match(syntax_name, pattern, 'Directory')
    end
  end
  
  if icons.collapsed then
    for icon_name, icon_value in pairs(icons.collapsed) do
      local syntax_name = 'dbui_collapsed_' .. icon_name
      local pattern = '^[[:blank:]]*' .. escape_pattern(icon_value)
      create_syntax_match(syntax_name, pattern, 'Directory')
    end
  end
  
  -- Create syntax for other icons
  local simple_icons = {
    'saved_query', 'new_query', 'tables', 'buffers', 'add_connection',
    'connection_ok', 'connection_error'
  }
  
  for _, icon_name in ipairs(simple_icons) do
    if icons[icon_name] then
      local syntax_name = 'dbui_' .. icon_name
      local pattern = '^[[:blank:]]*' .. escape_pattern(icons[icon_name])
      create_syntax_match(syntax_name, pattern)
    end
  end
  
  -- Special patterns for connection sources
  local expanded_db = escape_pattern(icons.expanded.db or '▾')
  local collapsed_db = escape_pattern(icons.collapsed.db or '▸')
  local connection_source_pattern = string.format('\\(%s\\s\\|%s\\s\\)\\@<!([^)]*)$', expanded_db, collapsed_db)
  create_syntax_match('dbui_connection_source', connection_source_pattern, 'Comment')
  
  -- Connection status patterns
  if icons.connection_ok then
    local pattern = escape_pattern(icons.connection_ok)
    create_syntax_match('dbui_connection_ok', pattern)
  end
  
  if icons.connection_error then
    local pattern = escape_pattern(icons.connection_error)
    create_syntax_match('dbui_connection_error', pattern)
  end
  
  -- Help text syntax
  create_syntax_match('dbui_help', '^".*$', 'Comment')
  vim.cmd('syn match dbui_help_key /^"\\s\\zs[^ ]*\\ze\\s-/ containedin=dbui_help')
  vim.cmd('hi default link dbui_help_key String')
  
  -- Set up highlight groups
  vim.cmd('hi default link dbui_add_connection Directory')
  vim.cmd('hi default link dbui_saved_query String')
  vim.cmd('hi default link dbui_new_query Operator')
  vim.cmd('hi default link dbui_buffers Constant')
  vim.cmd('hi default link dbui_tables Constant')
  
  -- Connection status colors
  if vim.o.background == 'light' then
    vim.cmd('hi dbui_connection_ok guifg=#00AA00 ctermfg=2')
    vim.cmd('hi dbui_connection_error guifg=#AA0000 ctermfg=1')
  else
    vim.cmd('hi dbui_connection_ok guifg=#88FF88 ctermfg=10')
    vim.cmd('hi dbui_connection_error guifg=#ff8888 ctermfg=9')
  end
  
  -- Set the syntax name
  vim.b.current_syntax = 'dbui'
end

-- Setup buffer-specific settings
function M.setup_buffer()
  -- Buffer options
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.buflisted = false
  vim.bo.swapfile = false
  vim.bo.modifiable = false
  
  -- Window options
  vim.wo.wrap = false
  vim.wo.spell = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.wo.winfixwidth = true
  vim.wo.cursorline = true
  
  -- Setup syntax highlighting
  M.setup()
end

return M