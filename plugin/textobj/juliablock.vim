if exists('g:loaded_textobj_juliablock')
  finish
endif

call textobj#user#plugin('juliablock', {
\      '-': {
\        'sfile': expand('<sfile>:p'),
\        'select-a': 'aj',  '*select-a-function*': 's:select_a',
\        'select-i': 'ij',  '*select-i-function*': 's:select_i'
\      },
\      'line': {
\        'sfile': expand('<sfile>:p'),
\        'select-a': 'aJ',  '*select-a-function*': 's:select_a_line',
\        'select-i': 'iJ',  '*select-i-function*': 's:select_i_line'
\      }
\    })


function! s:find_block(current_mode)

  if &ft != "julia"
    return s:abort()
  endif

  if !exists("b:julia_vim_loaded")
    echohl WarningMsg |
      \ echomsg "the julia-vim plugin is needed in order to use juliablock text objects" |
      \ echohl None | sleep 1
    return s:abort()
  endif

  if !exists("g:loaded_matchit")
    echohl WarningMsg |
      \ echomsg "matchit must be loaded in order to use juliablock text objects" |
      \ echohl None | sleep 1
    return s:abort()
  endif

  let flags = 'W'

  if b:txtobj_jl_did_select
    call setpos('.', b:txtobj_jl_last_start_pos)
    while expand("<cword>") !~# b:julia_end_keywords
      normal %
      if getpos('.') == b:txtobj_jl_last_start_pos
        " shouldn't happen, but let's avoid infinite loops anyway
        return s:abort()
      endif
    endwhile
    if !(a:current_mode[0] == 'a' && a:current_mode == b:txtobj_jl_last_mode)
      let flags .= 'c'
    endif
  elseif expand("<cword>") =~# b:julia_end_keywords
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

function! s:set_mark_tick(end_pos)
  call setpos('.', b:txtobj_jl_save_pos)
  normal! m`
  keepjumps call setpos('.', a:end_pos)
endfunction

function! s:get_save_pos()
  if !exists("b:txtobj_jl_save_pos") || !b:txtobj_jl_did_select
    let b:txtobj_jl_save_pos = getpos('.')
  endif
endfunction

function! s:repeated_find(ai_mode, select_mode)
  let repeat = v:count1 + (a:ai_mode == 'i' ? 1 : 0)
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
  let b:txtobj_jl_did_select = 0

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
  let b:txtobj_jl_did_select = 0

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

" we would need some autocmd event associated with visual mode,
" (exiting from visual mode, moving...) but there isn't any,
" so we resort to this crude hack (which still doesn't detect
" moving around)
vnoremap <silent><unique> <Esc> <Esc>:call TextobjJuliablockReset()<CR>


let g:loaded_textobj_juliablock = 1
