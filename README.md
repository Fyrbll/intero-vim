ORIGINAL PROJECT
================

Check out the [intero-neovim](https://github.com/parsonsmatt/intero-neovim) project!
Most of the code here comes directly from it. My changes are listed in detail below.

This project is actually an intended resolution to [Issue #149](https://github.com/parsonsmatt/intero-neovim/issues/149)
of the project above.

INSTALLATION
============

Here are the installation steps for Vim 8's built-in package manager:
- Create a **pack** folder inside your **.vim** folder
- Create a folder with any name you like (I call mine **packages**) in **pack**
- Create two folders called **start** and **opt** inside **packages**
- Put the entire **intero-vim** folder in your **opt** directory

USAGE
=====

This is the simple setup I'm working with right now, but please do check the README for the intero-vim project for a
better suggested configuration.

Add these lines to your **vimrc** file:

    " intero-vim plugin mappings ------ {{{
    augroup intero_maps
      autocmd!
      " Load the neomake plugin files
      autocmd FileType haskell packadd neomake
      " Load the intero-vim plugin files
      autocmd FileType haskell packadd intero-vim

      " Start intero
      autocmd FileType haskell nnoremap <localleader>is :InteroStart<CR>
      " Kill intero
      autocmd FileType haskell nnoremap <localleader>ik :InteroKill<CR>

      " Open intero/GHCi split horizontally
      autocmd FileType haskell nnoremap <localleader>io :InteroOpen<CR>
      " Hide intero/GHCi split
      autocmd FileType haskell nnoremap <localleader>ih :InteroHide<CR>

      " Manually save and reload
      autocmd FileType haskell nnoremap <localleader>ir :InteroReload<CR>

      " Load individual modules
      autocmd FileType haskell nnoremap <localleader>im :InteroLoadCurrentModule<CR>
      autocmd FileType haskell nnoremap <localleader>if :InteroLoadCurrentFile<CR>

      " Type-related information
      autocmd FileType haskell nnoremap <localleader>it <Plug>InteroGenericType
      autocmd FileType haskell nnoremap <localleader>iT <Plug>InteroType

      " Insert type above identifier under cursor
      autocmd FileType haskell nnoremap <localleader>ii :InteroTypeInsert<CR>

      " Navigation
      autocmd FileType haskell nnoremap <localleader>ig :InteroGoToDef<CR>

      " Managing targets
      " Prompts you to enter targets (no silent):
      " autocmd FileType haskell nnoremap <localleader>is :InteroSetTargets<SPACE>
    augroup END
    " }}}

missing job ids
===============

The variable `g:intero_job_id` is surplus to requirements and all lines
using it can be commented away/removed.

code changes
------------

-   **process.vim line 84**: commented `unlet g:intero_job_id` as all
    references to the variable are to be removed.
-   **process.vim line 172**: commented
    `let g:intero_job_id = b:terminal_job_id` as job ids don\'t exist in
    vim.
-   **process.vim line 193**: commented
    `let g:intero_job_id = b:terminal_job_id` as job ids don\'t exist in
    vim.

terminals in nvim vs vim
========================

neovim treats terminals as jobs, each of which needs to be attached to a
buffer. Consequently each terminal session is identified by its job id.

vim terminal sessions are buffers on their own so they\'re called
terminal buffers. These terminal sessions are thus identified by their
buffer ids.

code changes
------------

-   **repl.vim line 154**: changed `if !exists(g:intero_job_id)` to
    `if !exists(g:intero_buffer_id)`
-   **repl.vim line 186**: changed `if !exists(g:intero_job_id)` to
    `if !exists(g:intero_buffer_id)`
-   **process.vim line 162**: commented
    `exe 'below ' . a:height . ' split'` because a vim terminal session
    is its own buffer. There\'s no need to open a new buffer and then
    attach a terminal session to it.
-   **process.vim line 164**: commented `enew` for the same reason as
    line 162.
-   **process.vim line 181**: commented
    `exe 'below ' . a:height . ' split'` because a vim terminal session
    is its own buffer.
-   **process.vim line 184**: commented `enew` for the same reason as
    line 181.

jobsend() vs term\_sendkeys()
=============================

The vim function with a role closest to neovim\'s `jobsend()` is
`term_sendkeys()`.

arguments
---------

### jobsend()

| name | type | description |
|:---:|:---:|:--- |
| job | natural number | the job id of the terminal job to send keys to |
| data | string or string list | a single string with a command or a list of strings that will be sent as separate lines |

### term\_sendkeys()

| name | type | description |
|:---:|:---:|:--- |
| buf | natural number | the buffer id of the terminal buffer to send keys to |
| keys | string | a sequence of keystrokes - this is a single string, not a list |

return values
-------------

### jobsend()

1 if the write to the job\'s stdin succeeded, 0 otherwise

### term\_sendkeys()

no return value

side effects
------------

neither function has other effects worth mentioning

code changes
------------

`intero#compatibility#jobsend()` simply calls `term_sendkeys()`

-   **repl.vim line 154**: changed
    `jobsend(g:intero_job_id, add([a:str], ''))` to
    `intero#compatibility#jobsend(g:intero_buffer_id, add([a:str], ''))`
-   **repl.vim line 186**: changed `jobsend(g:intero_job_id, "\<C-u>")`
    to `intero#compatibility#jobsend(g:intero_buffer_id, ["\<C-u>"])`\
    The keystroke string is in a list because I\'ve made
    `intero#compatibility#jobsend()` take a string as its second
    argument.

neovim event handlers vs vim callbacks
======================================

The format for callbacks (or \"event handlers\") in neovim is found
using `:help job-control`.\
An event handler takes three arguments - a job id, the message, and the
event itself. The message argument can be a single string or a list of
strings.

vim callbacks are different. Their format is described in
**channel.txt** and can be accessed by running `:help channel-callback`.
A vim callback takes two arguments - the channel, and the message. The
message argument will be a single string and not a list.

code changes
------------

-   **process.vim line 199**: changed the function signature from\
    `function! s:on_stdout(jobid, lines, event) abort` to\
    `function! s:on_stdout(channel, lines) abort`.
-   **process.vim line 200**: changed\
    `for l:line_seg in a:lines` to\
    `for l:line_seg in split(a:lines, "\n")`\
    because vim callbacks receive single strings and not lists of
    strings.\
    I\'m not even sure if a newline is the right character to split
    on\...
-   **process.vim line 303**: changed the function signature from\
    `function! s:build_complete(job_id, data, event) abort` to\
    `function! s:build_complete(channel, data) abort`.
-   **process.vim line 304**: commented out the line
    `if(a:event ==# 'exit')` because `event` is not an argument
    available to vim callback functions.
-   **process.vim line 316**: commented out the line `endif` because we
    commented its matching `if` on line 304.

termopen() vs term\_start()
===========================

vim\'s closest counterpart to neovim\'s `termopen()` is `term_start()`.

arguments
---------

### termopen()

| name | type | description |
|:---:|:---:|:--- |
| cmd | string | command to be run by terminal job |
| opts | dictionary | keys are option names, values are option values and an option list can be found with `:help jobstart()` |

### term\_start()

| name | type | description |
|:---:|:---:|:--- |
| cmd | string | command to be run in terminal buffer |
| options | dictionary | keys are option names, values are option values, option list can be found with `:help term_start()` and `:help job-options` |

Useful options:
- \"term\_name\" sets the name of the terminal buffer
- \"term\_rows\" sets the height of the terminal buffer
- \"exit\_cb\" is the function to be called when the process exits
- \"out\_cb\" is the function to be called when the terminal buffer writes to stdout

return value
------------

### termopen()

returns 0 or -1 on failure (details omitted) and the job id otherwise

### term\_start()

buffer id of the terminal buffer it creates

side effects
------------

### termopen()

starts a terminal emulator session that\'s linked to the active buffer
at the time it was called

### term\_start()

opens a new buffer altogether to house the terminal emulator.

advised alterations
-------------------

In neovim, the process of creating a terminal job in a new buffer
involves first creating a buffer with a command like `split` or `enew`
before calling `termopen()`. This doesn\'t have to happen in vim because
`term_start()` creates a new buffer anyway. The preceding `enew` or
`split` can simply be done away with.

To open a vim terminal buffer below the current buffer we can prepend
the keyword `below` to `call intero#compatibility#termopen(...)`

code changes
------------

-   **process.vim line 165**: changed\
    `call termopen('stack ' . intero#util#stack_opts() . ' build intero', a:opts)`
    to
    `below call intero#compatibility#termopen('stack ' . intero#util#stack_opts() . ' build intero', a:opts)`
-   **process.vim line 166**: commented
    `execute 'file ' . s:compile_term_name` because it tries to rename
    the new buffer (which in vim\'s case will be an un-renameable
    terminal buffer).
-   **process.vim line 185**: changed\
    `call termopen(l:invocation.command, l:invocation.options)` to\
    `below call intero#compatibility#termopen(l:invocation.command, l:invocation.options)`.
-   **process.vim line 371**: changed\
    `let l:opts = { 'exit_cb': function('s:build_complete') }` to\
    `let l:opts = { 'exit_cb': function('s:build_complete'), 'term_name': s:compile_term_name, 'term_rows': 10 }`
-   **process.vim line 380**: changed\
    `\ 'out_cb': function('s:on_stdout')` to\
    `\ 'out_cb': function('s:on_stdout'), 'term_name': 'Intero', 'term_rows': 10`

new functions
=============

intero\#compatibility\#jobsend()
--------------------------------

Added\
`function! intero#compatibility#jobsend(buf, data) abort "{{{`\
`    call term_sendkeys(a:buf, join(a:data,"\<CR>"))`\
`endfunction "}}}`\
to **compatibility.vim**.

intero\#compatibility\#termopen()
---------------------------------

Added\
`function! intero#compatibility#termopen(cmd, opts) abort "{{{ `\
`    return term_start(a:cmd, a:opts)`\
`endfunction "}}}`\
to **compatibility.vim**

a mysterious issue
==================

After I run `intero#process#start()` the haskell buffer acquires the
alternate buffer name \'Intero\' while the intero REPL buffer acquires
the primary name \'Intero\'.\
I don\'t know why this happens but it means that when I run
`:echo bufwinnr('Intero')` it returns a positive integer even if no
window containing the intero buffer is visible.\
`intero#util#get_intero_window()` stops working properly because of this
and so I\'m replacing \'Intero\' in the function with the buffer id of
the terminal buffer running intero.

code changes
------------

-   **util.vim line 19**: changed\
    `return bufwinnr('Intero')` to\
    `return bufwinnr(g:intero_buffer_id)`
