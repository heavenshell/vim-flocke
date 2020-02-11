" File: flocke.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage: http://github.com/heavenshell/vim-flocke/
" Description: Format Python source code asynchronously with multiple formatters.
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

if get(b:, 'loaded_flocke')
  finish
endif

" version check
if !has('channel') || !has('job')
  echoerr '+channel and +job are required for flocke.vim'
  finish
endif

command! -buffer -nargs=* -range=0 -complete=customlist,flocke#complete Flocke :call flocke#run(<q-args>, <count>, <line1>, <line2>)

let b:loaded_flocke = 1

let &cpo = s:save_cpo
unlet s:save_cpo
