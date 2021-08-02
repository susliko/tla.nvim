" plugin/whid.vim
if exists('g:loaded_whid') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi def link WhidHeader      Number
hi def link WhidSubHeader   Identifier

command! TlaCheck lua require'tla'.check()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_whid = 1
