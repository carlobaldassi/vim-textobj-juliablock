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


let s:start_pattern = '\%(\.\s*\)\@<!\<\%(\%(staged\)\?function\|macro\|begin\|type\|immutable\|let\|do\|\%(bare\)\?module\|quote\|if\|for\|while\|try\)\>'
let s:end_pattern = '\<end\>'
" we need to skip everything within comments, strings and
" the 'end' keyword when it is used as a range rather than as
" the end of a block
let s:skip_pattern = 'synIDattr(synID(line("."),col("."),1),"name") =~ '
      \ . '"\\<julia\\%(ComprehensionFor\\|RangeEnd\\|QuotedBlockKeyword\\|InQuote\\|Comment[LM]\\|\\%([bv]\\|ip\\|MIME\\|Tri\\|Shell\\)\\?String\\|RegEx\\)\\>"'

function! s:find_block(current_mode)

  let save_pos = getpos('.')

  if &ft != "julia"
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
    while expand("<cword>") !~# s:end_pattern
      normal %
      if getpos('.') == b:txtobj_jl_last_start_pos
        " shouldn't happen, but let's avoid infinite loops anyway
        return s:abort(save_pos)
      endif
    endwhile
    if a:current_mode == 'i' || b:txtobj_jl_last_mode == 'i'
      let flags .= 'c'
    endif
  elseif expand("<cword>") =~# s:end_pattern
    let flags .= 'c'
    normal b
  endif
  let searchret = searchpair(s:start_pattern, '', s:end_pattern, flags, s:skip_pattern)
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
  normal m`
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
  normal e
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
