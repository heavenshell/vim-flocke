let s:save_cpo = &cpo
set cpo&vim

let g:flocke_formatters = get(g:, 'flocke_formatters', [])

let s:formatters = []
let s:results = []

function! s:get_range()
  " Get visual mode selection.
  let range = ''
  let mode = visualmode(1)
  if mode == 'v' || mode == 'V' || mode == ''
    let start_lnum = line("'<")
    let end_lnum = line("'>")
    return { 'start_lnum': start_lnum, 'end_lnum': end_lnum }
  endif

  return {}
endfunction

function! s:build_cmd(formatter, range) abort
  if a:range != {}
    " Visual selection
    if !has_key(a:formatter, 'range')
      " Formatter does not support range
      return 0
    endif
  endif
  if !has_key(a:formatter, 'cmd') || executable(a:formatter['cmd']) < 1
    return 0
  endif

  if has_key(a:formatter, 'args') && a:formatter['args'] != ''
    let cmd = printf('%s %s', a:formatter['cmd'], a:formatter['args'])
  else
    let cmd = printf('%s', a:formatter['cmd'])
  endif

  if has_key(a:formatter, 'range') && a:range != {}
    let range = printf(a:formatter['range'], a:range['start_lnum'], a:range['end_lnum'])
    let cmd = printf('%s %s', cmd, range)
  endif

  return cmd
endfunction

function! s:callback(ch, msg) abort
  call add(s:results, a:msg)
endfunction

function! s:exit_callback(ch, msg, range) abort
  if len(s:formatters) > 0
    let formatter = remove(s:formatters, 0, 0)[0]
    let cmd = s:build_cmd(formatter, a:range)
    if type(cmd) == 0
      call s:exit_callback(a:ch, a:msg, a:range)
      return
    endif
    let input = join(s:results, "\n")
    call flocke#job_run(cmd, input, a:range)
  else
    " All formatter is done.
    let view = winsaveview()
    silent execute '% delete'
    call setline(1, s:results)
    call winrestview(view)
  endif
endfunction

function! s:parse_options(args) abort
  let formatters = deepcopy(g:flocke_formatters)
  if len(a:args) == 0
    return formatters
  endif

  let results = []
  for arg in a:args
    for formatter in formatters
      if arg == formatter['cmd']
        call add(results, formatter)
      endif
    endfor
  endfor
  return results
endfunction

function! flocke#complete(lead, cmd, pos) abort
  let args = map(deepcopy(g:flocke_formatters), {_, v -> v['cmd']})
  let ret = filter(args, {_, v -> v =~# '^' . a:lead})
  return ret
endfunction

function! flocke#run(...) abort
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif
  let args = a:000[0] == '' ? [] : split(a:000[0], '')
  let s:formatters = s:parse_options(args)

  let bufnum = bufnr('%')
  let input = join(getbufline(bufnum, 1, '$'), "\n") . "\n"

  let range = s:get_range()
  let cmd = ''
  while len(s:formatters) > 0
    let formatter = remove(s:formatters, 0, 0)[0]
    let cmd = s:build_cmd(formatter, range)
    if type(cmd) == 1 && cmd != ''
      break
    endif
  endwhile
  if cmd == ''
    return
  endif

  call flocke#job_run(cmd, input, range)
endfunction

function! flocke#job_run(cmd, input, range) abort
  let s:results = []
  let s:job = job_start(a:cmd, {
    \ 'callback': {c, m -> s:callback(c, m)},
    \ 'exit_cb': {c, m -> s:exit_callback(c, m, a:range)},
    \ 'in_mode': 'nl',
    \ })
  let channel = job_getchannel(s:job)
  if ch_status(channel) ==# 'open'
    call ch_sendraw(channel, a:input)
    call ch_close_in(channel)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
