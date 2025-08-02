" Check if using Lua rewrite
if exists('g:loaded_db_ui_lua')
  " These functionalities will be handled by the Lua rewrite in the future
  " For now, provide basic fallbacks
  nnoremap <silent><buffer> <C-]> :echo "Foreign key navigation not yet implemented in Lua rewrite"<CR>
  nnoremap <silent><buffer> vic :echo "Cell value yanking not yet implemented in Lua rewrite"<CR>
  nnoremap <silent><buffer> yh :echo "Header yanking not yet implemented in Lua rewrite"<CR>
  nnoremap <silent><buffer> <Leader>R :echo "Layout toggle not yet implemented in Lua rewrite"<CR>
  finish
endif

" Legacy Vimscript mappings (only if Lua version not loaded)
nnoremap <silent><buffer> <Plug>(DBUI_JumpToForeignKey) :echo "Lua rewrite active - function not available"<CR>
nnoremap <silent><buffer> <Plug>(DBUI_YankCellValue) :echo "Lua rewrite active - function not available"<CR>
nnoremap <silent><buffer> <Plug>(DBUI_YankHeader) :echo "Lua rewrite active - function not available"<CR>
nnoremap <silent><buffer> <Plug>(DBUI_ToggleResultLayout) :echo "Lua rewrite active - function not available"<CR>
omap <silent><buffer> ic :echo "Lua rewrite active - function not available"<CR>

if get(g:, 'db_ui_disable_mappings', 0) || get(g:, 'db_ui_disable_mappings_dbout', 0)
  finish
endif

nnoremap <silent><buffer> <C-] :echo "Lua rewrite active - function not available"<CR>
nnoremap <silent><buffer> vic :echo "Lua rewrite active - function not available"<CR>
nnoremap <silent><buffer> yh :echo "Lua rewrite active - function not available"<CR>
nnoremap <silent><buffer> <Leader>R :echo "Lua rewrite active - function not available"<CR>
