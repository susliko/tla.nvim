if exists('g:loaded_tla') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! TlaCheck call luaeval("require'tla'.check(_A[1], _A[2])", [expand('%:p:r'), expand('%:e')])
command! TlaTranslate call luaeval("require'tla'.translate(_A[1], _A[2])", [expand('%:p'), expand('%:e')]) | edit

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tla = 1
