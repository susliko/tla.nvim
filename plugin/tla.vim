if exists('g:loaded_tla') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

let &cpo = s:save_cpo
unlet s:save_cpo


fun! TlaPlugin()
  lua for k in pairs(package.loaded) do if k:match("tla") then package.loaded[k] = nil end end
  lua require("tla").foo()
endfun

augroup TlaPlugin()
  autocmd!
augroup END 

let g:loaded_tla = 1
