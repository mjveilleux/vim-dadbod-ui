local M = {}
local utils = require('db_ui.utils')
local notifications = require('db_ui.notifications')
local config = require('db_ui.config')

-- Check if connection is SQL Server
function M.is_sql_server(db_url)
  local parsed = vim.fn['db#url#parse'](db_url)
  return parsed and (parsed.scheme == 'sqlserver' or parsed.scheme == 'mssql')
end

-- Build SQL Server CSV command
function M.build_sqlcmd_csv(db_url, query)
  local parsed = vim.fn['db#url#parse'](db_url)
  if not parsed then
    error('Invalid database URL')
  end
  
  local host = parsed.host or 'localhost'
  local port = parsed.port and tostring(parsed.port) or ''
  local database = (parsed.path or ''):gsub('^/', '')
  local user = parsed.user or ''
  local password = parsed.password or ''
  
  -- Build server string
  local server = host
  if port ~= '' then
    server = server .. ',' .. port
  end
  
  -- Build authentication
  local auth_flags = ''
  if user ~= '' and password ~= '' then
    auth_flags = string.format('-U "%s" -P "%s"', user, password)
  else
    auth_flags = '-E' -- Windows Authentication
  end
  
  -- Build database flag
  local db_flag = ''
  if database ~= '' then
    db_flag = string.format('-d "%s"', database)
  end
  
  -- Create temporary file for query
  local temp_file = vim.fn.tempname() .. '.sql'
  vim.fn.writefile({query}, temp_file)
  
  -- Build final command with CSV output
  local cmd = string.format(
    'sqlcmd -S "%s" %s %s -s"," -W -h-1 -i "%s"',
    server, auth_flags, db_flag, temp_file
  )
  
  return cmd, temp_file
end

-- Execute CSV query
function M.execute_csv_query(db_url, query)
  if not config.use_csv_mode or not M.is_sql_server(db_url) then
    return false -- Fall back to normal DB command
  end
  
  local success, cmd, temp_file = pcall(M.build_sqlcmd_csv, db_url, query)
  if not success then
    notifications.error('Failed to build SQL Server command: ' .. cmd)
    return false
  end
  
  -- Execute the command
  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  -- Clean up temp file
  if temp_file then
    vim.fn.delete(temp_file)
  end
  
  if exit_code ~= 0 then
    notifications.error('SQL Server query failed: ' .. output)
    return false
  end
  
  -- Parse and render the CSV output
  M.render_csv_table(output)
  return true
end

-- Parse CSV and create pretty table
function M.render_csv_table(csv_output)
  local lines = vim.split(csv_output:gsub('\r\n', '\n'):gsub('\r', '\n'), '\n')
  
  -- Remove empty lines and trim
  local data_lines = {}
  for _, line in ipairs(lines) do
    local trimmed = line:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed ~= '' then
      table.insert(data_lines, trimmed)
    end
  end
  
  if #data_lines == 0 then
    notifications.info('Query returned no results')
    return
  end
  
  -- Parse CSV data
  local rows = {}
  for _, line in ipairs(data_lines) do
    local row = M.parse_csv_line(line)
    table.insert(rows, row)
  end
  
  if #rows == 0 then
    notifications.info('Query returned no results')
    return
  end
  
  -- Create new buffer for results
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = math.min(120, vim.o.columns - 10),
    height = math.min(30, vim.o.lines - 10),
    row = 5,
    col = 5,
    style = 'minimal',
    border = 'rounded',
    title = ' Query Results '
  })
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'dbout')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Generate pretty table
  local table_lines = M.format_table(rows)
  
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, table_lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Close window on 'q'
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })
end

-- Parse a single CSV line (handle quoted values)
function M.parse_csv_line(line)
  local result = {}
  local i = 1
  local current_field = ''
  local in_quotes = false
  
  while i <= #line do
    local char = line:sub(i, i)
    
    if char == '"' then
      in_quotes = not in_quotes
    elseif char == ',' and not in_quotes then
      table.insert(result, current_field)
      current_field = ''
    else
      current_field = current_field .. char
    end
    
    i = i + 1
  end
  
  -- Add the last field
  table.insert(result, current_field)
  
  return result
end

-- Format data as pretty table
function M.format_table(rows)
  if #rows == 0 then
    return { 'No results' }
  end
  
  -- Calculate column widths
  local col_widths = {}
  for row_idx, row in ipairs(rows) do
    for col_idx, cell in ipairs(row) do
      local width = #tostring(cell)
      col_widths[col_idx] = math.max(col_widths[col_idx] or 0, width)
    end
  end
  
  -- Create table lines
  local lines = {}
  
  -- Header row (first row is assumed to be headers)
  local header_line = '│'
  for col_idx, cell in ipairs(rows[1]) do
    local padded = string.format(' %-' .. col_widths[col_idx] .. 's ', tostring(cell))
    header_line = header_line .. padded .. '│'
  end
  
  -- Top border
  local top_border = '┌'
  for col_idx = 1, #rows[1] do
    top_border = top_border .. string.rep('─', col_widths[col_idx] + 2)
    if col_idx < #rows[1] then
      top_border = top_border .. '┬'
    end
  end
  top_border = top_border .. '┐'
  
  -- Header separator
  local header_sep = '├'
  for col_idx = 1, #rows[1] do
    header_sep = header_sep .. string.rep('─', col_widths[col_idx] + 2)
    if col_idx < #rows[1] then
      header_sep = header_sep .. '┼'
    end
  end
  header_sep = header_sep .. '┤'
  
  -- Bottom border
  local bottom_border = '└'
  for col_idx = 1, #rows[1] do
    bottom_border = bottom_border .. string.rep('─', col_widths[col_idx] + 2)
    if col_idx < #rows[1] then
      bottom_border = bottom_border .. '┴'
    end
  end
  bottom_border = bottom_border .. '┘'
  
  -- Build table
  table.insert(lines, top_border)
  table.insert(lines, header_line)
  table.insert(lines, header_sep)
  
  -- Data rows (skip first row since it's the header)
  for row_idx = 2, #rows do
    local data_line = '│'
    for col_idx, cell in ipairs(rows[row_idx]) do
      local padded = string.format(' %-' .. col_widths[col_idx] .. 's ', tostring(cell))
      data_line = data_line .. padded .. '│'
    end
    table.insert(lines, data_line)
  end
  
  table.insert(lines, bottom_border)
  table.insert(lines, '')
  table.insert(lines, string.format('(%d rows)', #rows - 1))
  
  return lines
end

return M 