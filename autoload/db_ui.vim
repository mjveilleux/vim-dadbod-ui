" vim-dadbod-ui autoload functions
" Required for vim-dadbod-completion integration

function! db_ui#get_conn_info(db_key_name) abort
  " Main function that vim-dadbod-completion calls
  " This is the exact function name vim-dadbod-completion expects
  
  if has('nvim') && luaeval('_G.db_ui_get_conn_info ~= nil')
    return luaeval('_G.db_ui_get_conn_info(_A)', a:db_key_name)
  endif
  
  " Fallback for regular Vim
  if exists('b:dbui_db_key_name')
    let conn = get(b:, 'db', '')
    return {
      \ 'conn': conn,
      \ 'table': get(b:, 'dbui_table_name', ''),
      \ 'scheme': get(b:, 'dbui_schema_name', ''),
      \ 'connected': !empty(conn) ? 1 : 0,
      \ 'db': conn
    \ }
  endif
  
  return {}
endfunction

function! db_ui#setup_completion() abort
  " Set up completion for the current buffer
  
  " Only set up completion for SQL files with database connection
  if !exists('b:db') || empty(b:db) || &filetype !~# '\v(sql|mysql|postgresql|plsql)'
    return
  endif
  
  " Ensure buffer variables are properly set for vim-dadbod-completion
  if !exists('b:dbui_db_key_name') && exists('b:db')
    " Try to find the db_key_name from the connection
    " This is a fallback if it wasn't set properly
    let b:dbui_db_key_name = get(b:, 'dbui_db_key_name', '')
  endif
  
  " Get database info for better completion context
  if exists('b:dbui_db_key_name') && !empty(b:dbui_db_key_name)
    let l:db_info = db_ui#get_conn_info(b:dbui_db_key_name)
    
    " Set additional buffer variables for completion context
    if has_key(l:db_info, 'db_name') && !empty(l:db_info.db_name)
      let b:dbui_db_name = l:db_info.db_name
    endif
    
    if has_key(l:db_info, 'schema_support')
      let b:dbui_schema_support = l:db_info.schema_support
    endif
  endif
endfunction

" Note: No legacy compatibility functions needed - use db_ui#get_conn_info directly