if exists('g:loaded_textobj_juliablock')
  finish
endif

call textobj#user#plugin('juliablock', {
\      '-': {
\        '*sfile*': expand('<sfile>:p'),
\        'select-a': 'aj',  '*select-a-function*': 's:select_a',
\        'select-i': 'ij',  '*select-i-function*': 's:select_i'
\      }
\    })


function! s:find_block(current_mode)

  let save_pos = getpos('.')

  if &ft != "julia"
    return s:abort(save_pos)
  endif

  if !exists("b:julia_vim_loaded")
    echohl WarningMsg |
      \ echomsg "the julia-vim plugin is needed in order to use juliablock text objects" |
      \ echohl None | sleep 1
    return s:abort(save_pos)
  endif

  if !exists("g:loaded_matchit")
    echohl WarningMsg |
      \ echomsg "matchit must be loaded in order to use juliablock text objects" |
      \ echohl None | sleep 1
    return s:abort(save_pos)
  endif

  let flags = 'W'

  if b:txtobj_jl_did_select
    call setpos('.', b:txtobj_jl_last_start_pos)
    while expand("<cword>") !~# b:julia_end_keywords
      normal %
      if getpos('.') == b:txtobj_jl_last_start_pos
        " shouldn't happen, but let's avoid infinite loops anyway
        return s:abort(save_pos)
      endif
    endwhile
    if a:current_mode == 'i' || b:txtobj_jl_last_mode == 'i'
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
      return s:abort(save_pos)
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

  return [start_pos, end_pos, save_pos]
endfunction

function! s:abort(save_pos)
  call setpos('.', a:save_pos)
  call feedkeys("\<Esc>")
  return
endfunction

function! s:set_mark_tick(save_pos, end_pos)
  call setpos('.', a:save_pos)
  normal! m`
  keepjumps call setpos('.', a:end_pos)
endfunction

function! s:select_a()
  let ret_find_block = s:find_block("a")
  if empty(ret_find_block)
    return
  endif
  let [start_pos, end_pos, save_pos] = ret_find_block

  call s:set_mark_tick(save_pos, end_pos)

  call setpos('.', end_pos)
  normal! e
  let end_pos = getpos('.')
  let end_pos[2] += 1

  let b:txtobj_jl_doing_select = 1
  let b:txtobj_jl_last_mode = 'a'

  return ['V', start_pos, end_pos]
endfunction

function! s:select_i()
  let ret_find_block = s:find_block("i")
  if empty(ret_find_block)
    return
  endif
  let [start_pos, end_pos, save_pos] = ret_find_block

  if end_pos[1] <= start_pos[1]+1
    return s:abort(save_pos)
  endif

  let b:txtobj_jl_doing_select = 1
  let b:txtobj_jl_last_mode = 'i'

  call s:set_mark_tick(save_pos, end_pos)

  let start_pos[1] += 1
  let end_pos[1] -= 1
  let end_pos[2] = len(getline(end_pos[1])) + 1

  return ['V', start_pos, end_pos]
endfunction

function s:cursor_moved()
  let b:txtobj_jl_did_select = b:txtobj_jl_doing_select
  let b:txtobj_jl_doing_select = 0
endfunction

augroup TextobjJuliaBlocks
  au BufEnter,InsertEnter *.jl let b:txtobj_jl_did_select = 0 | let b:txtobj_jl_doing_select = 0 | let b:txtobj_jl_last_mode = ""
  au CursorMoved          *.jl call s:cursor_moved()
augroup END


let g:loaded_textobj_juliablock = 1
