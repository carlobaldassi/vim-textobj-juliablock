if exists('g:loaded_textobj_juliablock')
  finish
endif

call textobj#user#plugin('juliablock', {
\      '-': {
\        'sfile': expand('<sfile>:p'),
\        'select-a': 'aj',  'select-a-function': 's:select_a',
\        'select-i': 'ij',  'select-i-function': 's:select_i'
\      },
\      'line': {
\        'sfile': expand('<sfile>:p'),
\        'select-a': 'aJ',  'select-a-function': 's:select_a_line',
\        'select-i': 'iJ',  'select-i-function': 's:select_i_line'
\      },
\      'm': {
\        'sfile': expand('<sfile>:p'),
\        'move-N': ']e', 'move-N-function': 's:move_N',
\        'move-n': ']w', 'move-n-function': 's:move_n',
\        'move-p': '[b', 'move-p-function': 's:move_p',
\        'move-P': '[ge', 'move-P-function': 's:move_P'
\      },
\      'bm': {
\        'sfile': expand('<sfile>:p'),
\        'move-N': '][', 'move-N-function': 's:moveblock_N',
\        'move-p': '[]', 'move-p-function': 's:moveblock_p'
\      }
\    })

function! s:check_requirements()
  if &ft != "julia"
    return 0
  endif

  if !exists("b:julia_vim_loaded")
    echohl WarningMsg |
      \ echomsg "the julia-vim plugin is needed in order to use juliablock text objects" |
      \ echohl None | sleep 1
    return 0
  endif

  if !exists("g:loaded_matchit")
    echohl WarningMsg |
      \ echomsg "matchit must be loaded in order to use juliablock text objects" |
      \ echohl None | sleep 1
    return 0
  endif
  return 1
endfunction

function! s:find_block(current_mode)

  let flags = 'W'

  if b:txtobj_jl_did_select
    call setpos('.', b:txtobj_jl_last_start_pos)
    call s:cycle_until_end()
    if !(a:current_mode[0] == 'a' && a:current_mode == b:txtobj_jl_last_mode)
      let flags .= 'c'
    endif
  elseif s:on_end()
    let flags .= 'c'
    normal! lb
  endif
  " NOTE: b:julia_begin_keywords, b:julia_end_keywords and b:match_skip are
  "       defined in the julia-vim plugin
  let searchret = searchpair(b:julia_begin_keywords, '', b:julia_end_keywords, flags, b:match_skip)
  if searchret <= 0
    if !b:txtobj_jl_did_select
      return s:abort()
    else
      call setpos('.', b:txtobj_jl_last_end_pos)
    endif
  endif

  let end_pos = getpos('.')
  " Jump to match
  normal %
  let start_pos = getpos('.')

  let b:txtobj_jl_last_start_pos = copy(start_pos)
  let b:txtobj_jl_last_end_pos = copy(end_pos)

  return [start_pos, end_pos]
endfunction

function! s:abort()
  call setpos('.', b:txtobj_jl_save_pos)
  call feedkeys("\<Esc>")
  return 0
endfunction

function! s:set_mark_tick(pos)
  call setpos('.', b:txtobj_jl_save_pos)
  normal! m`
  keepjumps call setpos('.', a:pos)
endfunction

function! s:get_save_pos()
  if !exists("b:txtobj_jl_save_pos") || !b:txtobj_jl_did_select
    let b:txtobj_jl_save_pos = getpos('.')
  endif
endfunction

function! s:repeated_find(ai_mode, select_mode)
  if !s:check_requirements()
    return s:abort()
  endif

  let repeat = v:count1 + (a:ai_mode == 'i' && v:count1 > 1 ? 1 : 0)
  for c in range(repeat)
    let current_mode = (c < repeat - 1 ? 'a' : a:ai_mode) . a:select_mode
    let ret_find_block = s:find_block(current_mode)
    if empty(ret_find_block)
      return 0
    endif
    let [start_pos, end_pos] = ret_find_block
    call setpos('.', end_pos)
    let b:txtobj_jl_last_mode = current_mode
    if c < repeat - 1
      let b:txtobj_jl_doing_select = 0
      let b:txtobj_jl_did_select = 1
    endif
  endfor
  return [start_pos, end_pos]
endfunction

function! s:select_a(...)
  let select_mode = a:0 > 0 ? a:1 : 'v'
  call s:get_save_pos()
  let current_pos = getpos('.')
  let ret_find_block = s:repeated_find('a', select_mode)
  if empty(ret_find_block)
    return 0
  endif
  let [start_pos, end_pos] = ret_find_block

  call s:set_mark_tick(end_pos)

  normal! e
  let end_pos = getpos('.')

  let b:txtobj_jl_doing_select = 1

  " the textobj-user plugin triggers CursorMove only if
  " end_pos is different than the staring position
  " (this is needed when starting from the 'd' in 'end')
  if current_pos == end_pos
    call s:cursor_moved()
  endif

  return [select_mode, start_pos, end_pos]
endfunction

function! s:select_a_line()
  return s:select_a('V')
endfunction

function! s:select_i(...)
  let select_mode = a:0 > 0 ? a:1 : 'v'
  call s:get_save_pos()
  let current_pos = getpos('.')
  let ret_find_block = s:repeated_find('i', select_mode)
  if empty(ret_find_block)
    return 0
  endif
  let [start_pos, end_pos] = ret_find_block

  if end_pos[1] <= start_pos[1]+1
    return s:abort()
  endif

  call s:set_mark_tick(end_pos)

  let b:txtobj_jl_doing_select = 1

  let start_pos[1] += 1
  call setpos('.', start_pos)
  normal! ^
  let start_pos = getpos('.')
  let end_pos[1] -= 1
  let end_pos[2] = len(getline(end_pos[1]))

  " the textobj-user plugin triggers CursorMove only if
  " end_pos is different than the staring position
  " (this is needed when starting from the 'd' in 'end')
  if current_pos == end_pos
    call s:cursor_moved()
  endif

  return [select_mode, start_pos, end_pos]
endfunction

function! s:select_i_line()
  return s:select_i('V')
endfunction

function! s:on_end()
  return getline('.')[col('.')-1] =~# '\k' && expand("<cword>") =~# b:julia_end_keywords
endfunction

function! s:on_begin()
  return getline('.')[col('.')-1] =~# '\k' && expand("<cword>") =~# b:julia_begin_keywords
endfunction

function! s:cycle_until_end()
  let pos = getpos('.')
  while !s:on_end()
    normal %
    let c = 0
    if getpos('.') == pos || c > 1000
      " shouldn't happen, but let's avoid infinite loops anyway
      return 0
    endif
    let c += 1
  endwhile
endfunction

function! s:moveto_block_delim(toend, backwards)
  let pattern = a:toend ? b:julia_end_keywords : b:julia_begin_keywords
  let flags = a:backwards ? 'Wb' : 'W'
  let ret = 0
  for c in range(v:count1)
    if a:toend && a:backwards && s:on_end()
      normal! bh
    endif
    while 1
      let searchret = search(pattern, flags)
      if !searchret
	return ret
      endif
      exe "let skip = " . b:match_skip
      if !skip
	let ret = 1
	break
      endif
    endwhile
  endfor
  return ret
endfunction

function! s:compare_pos(pos1, pos2)
  if a:pos1[1] < a:pos2[1]
    return -1
  elseif a:pos1[1] > a:pos2[1]
    return 1
  elseif a:pos1[2] < a:pos2[2]
    return -1
  elseif a:pos1[2] > a:pos2[2]
    return 1
  else
    return 0
  endif
endfunction

function! s:move_N()
  call s:get_save_pos()
  if !s:check_requirements()
    return s:abort()
  endif

  let ret = s:moveto_block_delim(1, 0)
  if !ret
    return s:abort()
  endif

  normal! e
  let end_pos = getpos('.')
  normal %
  let start_pos = getpos('.')
  call s:set_mark_tick(end_pos)

  return ['v', start_pos, end_pos]
endfunction

function! s:move_n()
  call s:get_save_pos()
  if !s:check_requirements()
    return s:abort()
  endif

  let ret = s:moveto_block_delim(0, 0)
  if !ret
    return s:abort()
  endif

  let start_pos = getpos('.')
  call s:cycle_until_end()
  let end_pos = getpos('.')
  call s:set_mark_tick(start_pos)

  return ['v', start_pos, end_pos]
endfunction

function! s:move_p()
  call s:get_save_pos()
  if !s:check_requirements()
    return s:abort()
  endif

  let ret = s:moveto_block_delim(0, 1)
  if !ret
    return s:abort()
  endif

  let start_pos = getpos('.')
  call s:cycle_until_end()
  let end_pos = getpos('.')
  call s:set_mark_tick(start_pos)

  return ['v', start_pos, end_pos]
endfunction

function! s:move_P()
  call s:get_save_pos()
  if !s:check_requirements()
    return s:abort()
  endif

  let ret = s:moveto_block_delim(1, 1)
  if !ret
    return s:abort()
  endif

  normal! e
  let end_pos = getpos('.')
  normal %
  let start_pos = getpos('.')
  call s:set_mark_tick(end_pos)

  return ['v', start_pos, end_pos]
endfunction

function! s:moveto_currentblock_end()
  let flags = 'W'
  if s:on_end()
    let flags .= 'c'
    " NOTE: using "normal! lb" fails at the end of the file (?!)
    normal! l
    normal! b
  endif

  let ret = searchpair(b:julia_begin_keywords, '', b:julia_end_keywords, flags, b:match_skip)
  if ret <= 0
    return s:abort()
  endif

  normal! e
  return 1
endfunction

function! s:moveblock_N()
  call s:get_save_pos()
  if !s:check_requirements()
    return s:abort()
  endif

  let ret = 0
  for c in range(v:count1)
    let last_seen_pos = getpos('.')
    if s:on_end()
      normal! hel
      let save_pos = getpos('.')
      let ret_start = s:moveto_block_delim(0, 0)
      if ret_start
	let start1_pos = getpos('.')
      else
	let start1_pos = [0,0,0,0]
      endif
      call setpos('.', save_pos)
      if s:on_end()
	normal! h
      endif
      let ret_end = s:moveto_block_delim(1, 0)
      if ret_end
	let end1_pos = getpos('.')
      else
	let end1_pos = [0,0,0,0]
      endif

      if ret_start && (!ret_end || s:compare_pos(start1_pos, end1_pos) < 0)
	call setpos('.', start1_pos)
      else
	call setpos('.', save_pos)
      endif
    endif

    let moveret = s:moveto_currentblock_end()
    if !moveret
      call setpos('.', last_seen_pos)
      break
    endif

    let end_pos = getpos('.')
    normal %
    let start_pos = getpos('.')
    call setpos('.', end_pos)
    let ret = 1
  endfor
  if !ret
    return s:abort()
  endif

  call s:set_mark_tick(end_pos)

  return ['v', start_pos, end_pos]
endfunction

function! s:moveblock_p()
  call s:get_save_pos()
  if !s:check_requirements()
    return s:abort()
  endif

  let ret = 0
  for c in range(v:count1)
    let last_seen_pos = getpos('.')
    if s:on_begin()
      normal! lbh
      let save_pos = getpos('.')
      let ret_start = s:moveto_block_delim(0, 1)
      if ret_start
	let start1_pos = getpos('.')
      else
	let start1_pos = [0,0,0,0]
      endif
      call setpos('.', save_pos)
      let ret_end = s:moveto_block_delim(1, 1)
      if ret_end
	let end_pos1 = getpos('.')
      else
	let end_pos1 = [0,0,0,0]
      endif
      if ret_end && (!ret_start || s:compare_pos(start1_pos, end_pos1) < 0)
	call setpos('.', end_pos1)
      else
	call setpos('.', save_pos)
      endif
    endif

    let moveret = s:moveto_currentblock_end()
    if !moveret
      call setpos('.', last_seen_pos)
      break
    endif

    let end_pos = getpos('.')
    normal %
    let start_pos = getpos('.')
    call setpos('.', start_pos)
    let ret = 1
  endfor
  if !ret
    return s:abort()
  endif

  call s:set_mark_tick(start_pos)

  return ['v', start_pos, end_pos]
endfunction



function TextobjJuliablockReset()
  let b:txtobj_jl_did_select = 0
  let b:txtobj_jl_doing_select = 0
  let b:txtobj_jl_last_mode = ""
endfunction

function! s:cursor_moved()
  let b:txtobj_jl_did_select = b:txtobj_jl_doing_select
  let b:txtobj_jl_doing_select = 0
endfunction

augroup TextobjJuliaBlock
  au BufEnter,InsertEnter *.jl call TextobjJuliablockReset()
  au CursorMoved          *.jl call s:cursor_moved()
augroup END

" we would need some autocmd event associated with exiting from
" visual mode, but there isn't any, so we resort to this crude
" hack
vnoremap <silent><unique> <Esc> <Esc>:call TextobjJuliablockReset()<CR>


let g:loaded_textobj_juliablock = 1
