if exists('g:loaded_tla') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! TlaInstall lua require'tla.install'.install_tla2tools()
command! TlaCheck lua require'tla'.check()
command! TlaTranslate lua require'tla'.translate()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tla = 1
