
autocmd VimEnter * GitGutterLineNrHighlightsEnable
let g:gitgutter_highlight_linenrs = 1
let g:gitgutter_preview_win_floating = 1

nmap <leader>gnh <Plug>(GitGutterNextHunk)
nmap <leader>gph <Plug>(GitGutterPrevHunk)
nmap <leader>gsh <Plug>(GitGutterStageHunk)
nmap <leader>ghd <Plug>(GitGutterPreviewHunk)

