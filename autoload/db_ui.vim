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
  
  " If vim-dadbod-completion is available, it will set up completion automatically
  " We just need to ensure our buffer variables are set correctly
  
  " Ensure buffer variables are properly set for vim-dadbod-completion
  if !exists('b:dbui_db_key_name') && exists('b:db')
    " Try to find the db_key_name from the connection
    " This is a fallback if it wasn't set properly
    let b:dbui_db_key_name = get(b:, 'dbui_db_key_name', '')
  endif
endfunction

" Note: No legacy compatibility functions needed - use db_ui#get_conn_info directly