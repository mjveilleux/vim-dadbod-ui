local config = require('db_ui.config')
local utils = require('db_ui.utils')
local notifications = require('db_ui.notifications')

local M = {}

-- Drawer class
local Drawer = {}
Drawer.__index = Drawer

function M:new(dbui)
  local instance = setmetatable({}, Drawer)
  
  instance.dbui = dbui
  instance.show_details = false
  instance.show_help = false
  instance.show_dbout_list = false
  instance.content = {}
  instance.query = nil
  instance.connections = nil
  
  return instance
end

function Drawer:open(mods)
  if self:is_opened() then
    local winnr = self:get_winnr()
    if winnr > 0 then
      vim.cmd(winnr .. 'wincmd w')
    end
    return
  end
  
  mods = mods or ''
  if mods ~= '' then
    vim.cmd(mods .. ' new dbui')
  else
    local win_pos = config.win_position == 'left' and 'topleft' or 'botright'
    vim.cmd('vertical ' .. win_pos .. ' new dbui')
    vim.cmd('vertical ' .. win_pos .. ' resize ' .. config.winwidth)
  end
  
  -- Set buffer options
  vim.bo.filetype = 'dbui'
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.buflisted = false
  vim.bo.swapfile = false
  vim.bo.modifiable = false
  
  -- Set window options
  vim.wo.wrap = false
  vim.wo.spell = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.wo.winfixwidth = true
  
  self:render()
  self:setup_mappings()
  self:setup_autocmds()
  
  -- Trigger user autocommand
  vim.cmd('silent! doautocmd User DBUIOpened')
end

function Drawer:setup_mappings()
  local opts = { buffer = true, silent = true }

  if not config.disable_mappings and not config.disable_mappings_dbui then
    vim.keymap.set('n', 'o', '<Plug>(DBUI_SelectLine)', opts)
    vim.keymap.set('n', '<CR>', '<Plug>(DBUI_SelectLine)', opts)
    vim.keymap.set('n', '<2-LeftMouse>', '<Plug>(DBUI_SelectLine)', opts)
    vim.keymap.set('n', 'S', '<Plug>(DBUI_SelectLineVsplit)', opts)
    vim.keymap.set('n', 'R', '<Plug>(DBUI_Redraw)', opts)
    vim.keymap.set('n', 'd', '<Plug>(DBUI_DeleteLine)', opts)
    vim.keymap.set('n', 'A', '<Plug>(DBUI_AddConnection)', opts)
    vim.keymap.set('n', 'H', '<Plug>(DBUI_ToggleDetails)', opts)
    vim.keymap.set('n', 'r', '<Plug>(DBUI_RenameLine)', opts)
    vim.keymap.set('n', 'q', '<Plug>(DBUI_Quit)', opts)
    vim.keymap.set('n', '<c-k>', '<Plug>(DBUI_GotoFirstSibling)', opts)
    vim.keymap.set('n', '<c-j>', '<Plug>(DBUI_GotoLastSibling)', opts)
    vim.keymap.set('n', '<C-p>', '<Plug>(DBUI_GotoParentNode)', opts)
    vim.keymap.set('n', '<C-n>', '<Plug>(DBUI_GotoChildNode)', opts)
    vim.keymap.set('n', 'K', '<Plug>(DBUI_GotoPrevSibling)', opts)
    vim.keymap.set('n', 'J', '<Plug>(DBUI_GotoNextSibling)', opts)
  end
end

function Drawer:setup_autocmds()
  local augroup = vim.api.nvim_create_augroup('dbui_drawer', { clear = true })
  
  vim.api.nvim_create_autocmd('BufUnload', {
    group = augroup,
    buffer = 0,
    callback = function()
      vim.cmd('silent! doautocmd User DBUIClosed')
    end
  })
end

function Drawer:get_split_command()
  local query_win_pos = config.win_position == 'left' and 'botright' or 'topleft'
  return 'vertical ' .. query_win_pos .. ' split'
end

function Drawer:is_opened()
  return self:get_winnr() > 0
end

function Drawer:get_winnr()
  for i = 1, vim.fn.winnr('$') do
    if vim.fn.getwinvar(i, '&filetype') == 'dbui' then
      return i
    end
  end
  return 0
end

function Drawer:toggle()
  if self:is_opened() then
    return self:quit()
  else
    return self:open()
  end
end

function Drawer:quit()
  if self:is_opened() then
    local winnr = self:get_winnr()
    local bufnr = vim.fn.winbufnr(winnr)
    vim.cmd('bd' .. bufnr)
  end
end

function Drawer:redraw()
  local item = self:get_current_item()
  if item.level == 0 then
    return self:render({ dbs = true, queries = true })
  else
    return self:render({ db_key_name = item.dbui_db_key_name, queries = true })
  end
end

function Drawer:focus()
  if vim.bo.filetype == 'dbui' then
    return false
  end
  
  local winnr = self:get_winnr()
  if winnr > 0 then
    vim.cmd(winnr .. 'wincmd w')
    return true
  end
  return false
end

function Drawer:render(opts)
  opts = opts or {}
  local restore_win = self:focus()
  
  if vim.bo.filetype ~= 'dbui' then
    return
  end
  
  if opts.dbs then
    local start_time = vim.loop.hrtime()
    notifications.info('Refreshing all databases...')
    self.dbui:populate_dbs()
    local elapsed = (vim.loop.hrtime() - start_time) / 1e9
    notifications.info(string.format('Refreshed all databases after %.2f sec.', elapsed))
  end
  
  if opts.db_key_name then
    local db = self.dbui.dbs[opts.db_key_name]
    notifications.info('Refreshing database ' .. db.name .. '...')
    local start_time = vim.loop.hrtime()
    self.dbui.dbs[opts.db_key_name] = self:populate(db)
    local elapsed = (vim.loop.hrtime() - start_time) / 1e9
    notifications.info(string.format('Refreshed database %s after %.2f sec.', db.name, elapsed))
  end
  
  vim.cmd('redraw!')
  local view = vim.fn.winsaveview()
  self.content = {}
  
  self:render_help()
  
  for _, db in ipairs(self.dbui.dbs_list) do
    if opts.queries then
      self:load_saved_queries(self.dbui.dbs[db.key_name])
    end
    self:add_db(self.dbui.dbs[db.key_name])
  end
  
  if #self.dbui.dbs_list == 0 then
    self:add('" No connections', 'noaction', 'help', '', '', 0)
    self:add('Add connection', 'call_method', 'add_connection', config.icons.add_connection, '', 0)
  end
  
  -- Render dbout list if enabled
  if not vim.tbl_isempty(self.dbui.dbout_list) then
    self:add_dbout_list()
  end
  
  -- Update buffer content
  vim.bo.modifiable = true
  local lines = {}
  for _, item in ipairs(self.content) do
    table.insert(lines, item.label)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.modifiable = false
  
  vim.fn.winrestview(view)
  
  if restore_win then
    vim.cmd('wincmd p')
  end
end

function Drawer:render_help()
  if not self.show_help then
    return
  
  local help_text = {
    '" Press ? for help',
    '" o or <CR> to open',
    '" S to open in split',
    '" R to refresh',
    '" d to delete',
    '" A to add connection',
    '" q to quit',
    ''
  }
  
  for _, text in ipairs(help_text) do
    self:add(text, 'noaction', 'help', '', '', 0)
  end
end

function Drawer:add(label, action, type, icon, file_path, level)
  local item = {
    label = string.rep('  ', level) .. icon .. ' ' .. label,
    action = action,
    type = type,
    file_path = file_path,
    level = level,
    dbui_db_key_name = self.current_db_key_name or ''
  }
  table.insert(self.content, item)
end

function Drawer:add_db(db)
  self.current_db_key_name = db.key_name
  
  local icon = db.expanded and config.icons.expanded.db or config.icons.collapsed.db
  if db.conn ~= '' then
    icon = config.icons.connection_ok .. ' ' .. icon
  elseif db.conn_error ~= '' then
    icon = config.icons.connection_error .. ' ' .. icon
  end
  
  self:add(db.name, 'toggle', 'db', icon, '', 0)
  
  if db.expanded then
    self:add_db_buffers(db, 1)
    self:add_db_saved_queries(db, 1)
    
    if db.conn ~= '' then
      if db.schema_support then
        self:add_db_schemas(db, 1)
      else
        self:add_db_tables(db, 1)
      end
    end
  end
  
  self.current_db_key_name = ''
end

function Drawer:add_db_buffers(db, level)
  if #db.buffers.list == 0 then
    return
  end
  
  local icon = db.buffers.expanded and config.icons.expanded.buffers or config.icons.collapsed.buffers
  self:add('Buffers', 'toggle', 'buffers', icon, '', level)
  
  if db.buffers.expanded then
    for _, buffer in ipairs(db.buffers.list) do
      local filename = vim.fn.fnamemodify(buffer, ':t')
      self:add(filename, 'open', 'buffer', config.icons.buffers, buffer, level + 1)
    end
  end
end

function Drawer:add_db_saved_queries(db, level)
  if #db.saved_queries.list == 0 then
    return
  end
  
  local icon = db.saved_queries.expanded and config.icons.expanded.saved_queries or config.icons.collapsed.saved_queries
  self:add('Saved Queries', 'toggle', 'saved_queries', icon, '', level)
  
  if db.saved_queries.expanded then
    for _, query in ipairs(db.saved_queries.list) do
      local filename = vim.fn.fnamemodify(query, ':t')
      self:add(filename, 'open', 'saved_query', config.icons.saved_query, query, level + 1)
    end
    
    -- Add new query option
    self:add('New Query', 'open', 'new_query', config.icons.new_query, '', level + 1)
  end
end

function Drawer:add_db_tables(db, level)
  if #db.tables.list == 0 then
    return
  end
  
  local icon = db.tables.expanded and config.icons.expanded.tables or config.icons.collapsed.tables
  self:add('Tables', 'toggle', 'tables', icon, '', level)
  
  if db.tables.expanded then
    for _, table in ipairs(db.tables.list) do
      local table_icon = db.tables.items[table].expanded and config.icons.expanded.table or config.icons.collapsed.table
      self:add(table, 'toggle', 'table', table_icon, '', level + 1)
      
      if db.tables.items[table].expanded then
        -- Add table helpers
        for helper_name, _ in pairs(config.table_helpers) do
          self:add(helper_name, 'open', 'table_helper', '', '', level + 2)
        end
      end
    end
  end
end

function Drawer:add_db_schemas(db, level)
  -- Schema support implementation would go here
  return
end

function Drawer:add_dbout_list()
  if self.show_dbout_list then
    for _, dbout in ipairs(self.dbui.dbout_list) do
      local filename = vim.fn.fnamemodify(dbout, ':t')
      self:add(filename, 'open', 'dbout', config.icons.saved_query, dbout, 0)
    end
  end
end

function Drawer:get_current_item()
  local line = vim.fn.line('.')
  return self.content[line] or {}
end

function Drawer:toggle_line(edit_action)
  local item = self:get_current_item()
  
  if item.action == 'noaction' then
    return
  end
  
  if item.action == 'call_method' then
    return self[item.type](self)
  end
  
  if item.type == 'dbout' then
    if self:get_query() then
      self:get_query():focus_window()
      vim.cmd('pedit ' .. item.file_path)
    end
    return
  end
  
  if item.action == 'open' then
    return self:get_query():open(item, edit_action)
  end
  
  local db = self.dbui.dbs[item.dbui_db_key_name]
  local tree = db
  
  if item.type ~= 'db' then
    tree = self:get_nested(db, item.type)
  end
  
  tree.expanded = not tree.expanded
  
  if item.type == 'db' then
    self:toggle_db(db)
  end
  
  return self:render()
end

function Drawer:get_nested(db, path)
  local parts = vim.split(path, '->')
  local current = db
  
  for _, part in ipairs(parts) do
    if current[part] then
      current = current[part]
    end
  end
  
  return current
end

function Drawer:toggle_db(db)
  if not db.expanded then
    return db
  end
  
  self:load_saved_queries(db)
  self.dbui:connect(db)
  
  if db.conn ~= '' then
    self:populate(db)
  end
end

function Drawer:load_saved_queries(db)
  if db.save_path ~= '' then
    db.saved_queries.list = vim.fn.glob(db.save_path .. '/*', true, true)
  end
end

function Drawer:populate(db)
  if db.conn == '' and db.conn_tried then
    self.dbui:connect(db)
  end
  
  if db.schema_support then
    return self:populate_schemas(db)
  else
    return self:populate_tables(db)
  end
end

function Drawer:populate_tables(db)
  db.tables.list = {}
  
  if db.conn == '' then
    return db
  end
  
  -- This would use vim-dadbod to get tables
  local success, tables = pcall(vim.fn['db#adapter#call'], db.conn, 'tables', {db.conn}, {})
  
  if success then
    db.tables.list = tables
    self:populate_table_items(db.tables)
  end
  
  return db
end

function Drawer:populate_schemas(db)
  -- This would be implemented with schema support
  return db
end

function Drawer:populate_table_items(tables_obj)
  for _, table in ipairs(tables_obj.list) do
    if not tables_obj.items[table] then
      tables_obj.items[table] = { expanded = false }
    end
  end
end

function Drawer:delete_line()
  local item = self:get_current_item()
  
  if item.action == 'noaction' then
    return
  end
  
  if item.action == 'toggle' and item.type == 'db' then
    local db = self.dbui.dbs[item.dbui_db_key_name]
    if db.source ~= 'file' then
      return notifications.error('Cannot delete this connection.')
    end
    return self:delete_connection(db)
  end
  
  if item.action ~= 'open' or item.type ~= 'buffer' then
    return
  end
  
  local db = self.dbui.dbs[item.dbui_db_key_name]
  
  if item.saved then
    local choice = vim.fn.confirm('Are you sure you want to delete this saved query?', '&Yes\n&No')
    if choice ~= 1 then
      return
    end
    
    vim.fn.delete(item.file_path)
    
    -- Remove from saved queries list
    for i, query in ipairs(db.saved_queries.list) do
      if query == item.file_path then
        table.remove(db.saved_queries.list, i)
        break
      end
    end
    
    -- Remove from buffers list
    for i, buf in ipairs(db.buffers.list) do
      if buf == item.file_path then
        table.remove(db.buffers.list, i)
        break
      end
    end
    
    notifications.info('Deleted.')
  end
  
  if self.dbui:is_tmp_location_buffer(db, item.file_path) then
    local choice = vim.fn.confirm('Are you sure you want to delete query?', '&Yes\n&No')
    if choice ~= 1 then
      return
    end
    
    vim.fn.delete(item.file_path)
    
    -- Remove from buffers list
    for i, buf in ipairs(db.buffers.list) do
      if buf == item.file_path then
        table.remove(db.buffers.list, i)
        break
      end
    end
    
    notifications.info('Deleted.')
  end
  
  -- Close buffer if open
  local bufnr = vim.fn.bufnr(item.file_path)
  if bufnr ~= -1 then
    local winnr = vim.fn.bufwinnr(bufnr)
    if winnr > 0 then
      vim.cmd(winnr .. 'wincmd w')
      vim.cmd('b#')
    end
    vim.cmd('bw! ' .. bufnr)
  end
  
  self:focus()
  self:render()
end

function Drawer:toggle_help()
  self.show_help = not self.show_help
  return self:render()
end

function Drawer:toggle_details()
  self.show_details = not self.show_details
  return self:render()
end

function Drawer:add_connection()
  if not self.connections then
    self.connections = require('db_ui.connections'):new(self)
  end
  return self.connections:add()
end

function Drawer:delete_connection(db)
  if not self.connections then
    self.connections = require('db_ui.connections'):new(self)
  end
  return self.connections:delete(db)
end

function Drawer:get_query()
  if not self.query then
    self.query = require('db_ui.query'):new(self)
  end
  return self.query
end

-- Navigation functions
function Drawer:goto_sibling(direction)
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_item = self:get_current_item()
  
  if not current_item or current_item.level == nil then
    return
  end
  
  local target_line = nil
  local current_level = current_item.level
  
  if direction == 'first' then
    -- Find first sibling at same level
    for i = 1, #self.content do
      local item = self.content[i]
      if item.level == current_level then
        target_line = i
        break
      end
    end
  elseif direction == 'last' then
    -- Find last sibling at same level
    for i = #self.content, 1, -1 do
      local item = self.content[i]
      if item.level == current_level then
        target_line = i
        break
      end
    end
  elseif direction == 'next' then
    -- Find next sibling at same level
    for i = current_line + 1, #self.content do
      local item = self.content[i]
      if item.level == current_level then
        target_line = i
        break
      elseif item.level < current_level then
        break -- Gone up a level, no more siblings
      end
    end
  elseif direction == 'prev' then
    -- Find previous sibling at same level
    for i = current_line - 1, 1, -1 do
      local item = self.content[i]
      if item.level == current_level then
        target_line = i
        break
      elseif item.level < current_level then
        break -- Gone up a level, no more siblings
      end
    end
  end
  
  if target_line then
    vim.api.nvim_win_set_cursor(0, {target_line, 0})
  end
end

function Drawer:goto_parent()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_item = self:get_current_item()
  
  if not current_item or current_item.level == nil or current_item.level == 0 then
    return
  end
  
  local target_level = current_item.level - 1
  
  -- Find parent (first item with level one less than current)
  for i = current_line - 1, 1, -1 do
    local item = self.content[i]
    if item.level == target_level then
      vim.api.nvim_win_set_cursor(0, {i, 0})
      break
    end
  end
end

function Drawer:goto_child()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_item = self:get_current_item()
  
  if not current_item or current_item.level == nil then
    return
  end
  
  local target_level = current_item.level + 1
  
  -- Find first child (next item with level one more than current)
  for i = current_line + 1, #self.content do
    local item = self.content[i]
    if item.level == target_level then
      vim.api.nvim_win_set_cursor(0, {i, 0})
      break
    elseif item.level <= current_item.level then
      break -- No children found
    end
  end
end

return M