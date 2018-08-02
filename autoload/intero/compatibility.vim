function! intero#compatibility#jobsend(buf, data) abort "{{{
  call term_sendkeys(a:buf, join(a:data,"\<CR>"))
endfunction "}}}

function! intero#compatibility#termopen(cmd, opts) abort "{{{
  return term_start(a:cmd, a:opts)
endfunction "}}}
