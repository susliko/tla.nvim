" plugin/whid.vim
if exists('g:loaded_tla') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! TlaCheck lua require'tla'.check()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tla = 1
