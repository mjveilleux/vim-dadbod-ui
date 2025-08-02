" Check if using Lua rewrite
if exists('g:loaded_db_ui_lua')
  " Mappings are handled in plugin/db_ui.lua
  finish
endif

" Legacy Vimscript mappings (only if Lua version not loaded)
if get(g:, 'db_ui_disable_mappings', 0) || get(g:, 'db_ui_disable_mappings_dbui', 0)
  finish
endif

" Note: These mappings require the old autoload functions
" If you see errors, you're using the Lua rewrite and should set g:loaded_db_ui_lua = 1
nnoremap <silent><buffer> o :echo "Using Lua rewrite - mappings handled automatically"<CR>
nnoremap <silent><buffer> <CR> :echo "Using Lua rewrite - mappings handled automatically"<CR>
nnoremap <silent><buffer> S :echo "Using Lua rewrite - mappings handled automatically"<CR>
nnoremap <silent><buffer> R :echo "Using Lua rewrite - mappings handled automatically"<CR>
nnoremap <silent><buffer> d :echo "Using Lua rewrite - mappings handled automatically"<CR>
nnoremap <silent><buffer> A :echo "Using Lua rewrite - mappings handled automatically"<CR>
nnoremap <silent><buffer> H :echo "Using Lua rewrite - mappings handled automatically"<CR>
nnoremap <silent><buffer> r :echo "Using Lua rewrite - mappings handled automatically"<CR>
nnoremap <silent><buffer> q :echo "Using Lua rewrite - mappings handled automatically"<CR>
