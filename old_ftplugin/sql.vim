" Check if using Lua rewrite
if exists('g:loaded_db_ui_lua')
  " Mappings are handled in the Lua setup
  finish
endif

" Legacy Vimscript mappings (only if Lua version not loaded)
if get(g:, 'db_ui_disable_mappings', 0) || get(g:, 'db_ui_disable_mappings_sql', 0)
  finish
endif

" Note: These mappings require the old autoload functions
" The Lua rewrite handles these mappings automatically
nnoremap <silent><buffer> <Leader>W :echo "Using Lua rewrite - mapping handled automatically"<CR>
nnoremap <silent><buffer> <Leader>E :echo "Using Lua rewrite - mapping handled automatically"<CR>
nnoremap <silent><buffer> <Leader>S :echo "Using Lua rewrite - mapping handled automatically"<CR>
vnoremap <silent><buffer> <Leader>S :echo "Using Lua rewrite - mapping handled automatically"<CR>
