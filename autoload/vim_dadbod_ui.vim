" vim-dadbod-ui autoload functions
" Required for vim-dadbod-completion integration

function! vim_dadbod_ui#completion#omni(findstart, base) abort
  " Main omnifunc for vim-dadbod-completion
  " This function is called by vim-dadbod-completion for autocompletion
  
  if a:findstart
    " Find the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\a'
      let start -= 1
    endwhile
    return start
  else
    " Get completion items
    return vim_dadbod_ui#completion#get_completion(a:base)
  endif
endfunction

function! vim_dadbod_ui#completion#get_completion(base) abort
  " Get completion items for the given base
  
  " Check if we have a database connection
  if !exists('b:db') || empty(b:db)
    return []
  endif
  
  try
    " Call vim-dadbod-completion directly
    if exists('*vim_dadbod_completion#omni')
      return vim_dadbod_completion#omni(0, a:base)
    endif
    
    " Fallback to basic completion
    return vim_dadbod_ui#completion#get_basic_completion(a:base)
  catch
    return []
  endtry
endfunction

function! vim_dadbod_ui#completion#get_basic_completion(base) abort
  " Basic completion when vim-dadbod-completion is not available
  
  let items = []
  
  " Add SQL keywords
  let sql_keywords = [
    \ 'SELECT', 'FROM', 'WHERE', 'INSERT', 'UPDATE', 'DELETE',
    \ 'JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'INNER JOIN',
    \ 'GROUP BY', 'ORDER BY', 'HAVING', 'LIMIT',
    \ 'DISTINCT', 'AS', 'AND', 'OR', 'NOT', 'NULL',
    \ 'CREATE', 'DROP', 'ALTER', 'TABLE', 'INDEX',
    \ 'PRIMARY KEY', 'FOREIGN KEY', 'REFERENCES'
  \ ]
  
  for keyword in sql_keywords
    if keyword =~? '^' . a:base
      call add(items, {
        \ 'word': keyword,
        \ 'menu': '[SQL]',
        \ 'kind': 'k'
      \ })
    endif
  endfor
  
  return items
endfunction

function! vim_dadbod_ui#get_conn_info(db_key_name) abort
  " Get connection info for a database
  " This is called by vim-dadbod-completion and our Lua code
  
  if has('nvim') && luaeval('_G.db_ui_get_conn_info ~= nil')
    return luaeval('_G.db_ui_get_conn_info(_A)', a:db_key_name)
  endif
  
  " Fallback for regular Vim
  if exists('b:dbui_db_key_name')
    return {
      \ 'conn': get(b:, 'db', ''),
      \ 'table': get(b:, 'dbui_table_name', ''),
      \ 'schema': get(b:, 'dbui_schema_name', '')
    \ }
  endif
  
  return {}
endfunction

function! vim_dadbod_ui#setup_completion() abort
  " Set up completion for the current buffer
  
  " Only set up completion for SQL files with database connection
  if !exists('b:db') || empty(b:db) || &filetype !~# '\v(sql|mysql|postgresql|plsql)'
    return
  endif
  
  " Set omnifunc
  setlocal omnifunc=vim_dadbod_ui#completion#omni
  
  " Set up completefunc as backup
  setlocal completefunc=vim_dadbod_ui#completion#omni
  
  " If vim-dadbod-completion is available, let it handle completion
  if exists('g:vim_dadbod_completion_mark')
    " vim-dadbod-completion is loaded, let it handle things
    return
  endif
  
  " Enable completion popup
  if has('patch-8.1.1882') || has('nvim-0.4.0')
    setlocal completeopt+=popup
  endif
endfunction

" For backwards compatibility - some completion plugins may call this
function! vim_dadbod_ui#dbui#get_conn_info(db_key_name) abort
  return vim_dadbod_ui#get_conn_info(a:db_key_name)
endfunction