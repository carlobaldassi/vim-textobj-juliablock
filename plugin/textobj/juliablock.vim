if exists('g:loaded_textobj_juliablock')  "{{{1
  finish
endif

if !exists("loaded_matchit")
  finish
endif

" Interface  "{{{1
call textobj#user#plugin('juliablock', {
\      '-': {
\        '*sfile*': expand('<sfile>:p'),
\        'select-a': 'aj',  '*select-a-function*': 's:select_a',
\        'select-i': 'ij',  '*select-i-function*': 's:select_i'
\      }
\    })

" Misc.  "{{{1
let s:start_pattern = '\%(\.\s*\)\@<!\<\%(\%(staged\)\?function\|macro\|begin\|type\|immutable\|let\|do\|\%(bare\)\?module\|quote\|if\|for\|while\|try\)\>'
let s:end_pattern = '\<end\>'
" we need to skip everything within comments, strings and
" the 'end' keyword when it is used as a range rather than as
" the end of a block
let s:skip_pattern = 'synIDattr(synID(line("."),col("."),1),"name") =~ '
      \ . '"\\<julia\\%(ComprehensionFor\\|RangeEnd\\|QuotedBlockKeyword\\|InQuote\\|Comment[LM]\\|\\%([bv]\\|ip\\|MIME\\|Tri\\|Shell\\)\\?String\\|RegEx\\)\\>"'

function! s:find_block()

  if &ft != "julia"
    call feedkeys("\<Esc>")
    return
  endif

  let flags = 'W'
  if expand("<cword>") == "end"
    let flags = 'cW'
  endif

  let save_pos = getpos('.')
  keepjumps normal ^
  keepjumps let searchret = searchpair(s:start_pattern,'',s:end_pattern, flags, s:skip_pattern)
  if searchret <= 0
    call setpos('.', save_pos)
    call feedkeys("\<Esc>")
    return
  endif

  let end_pos = getpos('.')
  " Jump to match
  keepjumps normal %
  let start_pos = getpos('.')

  return [start_pos, end_pos, save_pos]
endfunction

function! s:select_a()
  let ret_find_block = s:find_block()
  if empty(ret_find_block)
    return
  endif
  let [start_pos, end_pos, save_pos] = ret_find_block

  keepjumps call setpos('.', save_pos)
  normal m`
  keepjumps call setpos('.', end_pos)

  return ['V', start_pos, end_pos]
endfunction

function! s:select_i()
  let ret_find_block = s:find_block()
  if empty(ret_find_block)
    return
  endif
  let [start_pos, end_pos, save_pos] = ret_find_block

  if end_pos[1] <= start_pos[1]+1
    call setpos('.', save_pos)
    call feedkeys("\<Esc>")
    return
  endif

  keepjumps call setpos('.', save_pos)
  normal m`
  keepjumps call setpos('.', end_pos)

  let start_pos[1] += 1
  let end_pos[1] -= 1

  return ['V', start_pos, end_pos]
endfunction

" Fin.  "{{{1

let g:loaded_textobj_juliablock = 1

" __END__
" vim: foldmethod=marker
