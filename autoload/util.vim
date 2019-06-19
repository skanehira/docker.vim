let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:DATE = s:V.import('DateTime')

let s:last_buffer = 0
let s:last_popup_window = 0

function! util#_parse_id(id) abort
    return a:id[7:19]
endfunction

function! util#_parse_unix_date(date) abort
    return s:DATE.from_unix_time(a:date).format('%F %T')
endfunction

function! util#_parse_size(size) abort
    return printf("%.2fMB", a:size / 1024 / 1024.0)
endfunction

function! util#_popup_window(content) abort
    call popup_close(s:last_popup_window)
    call popup_create(a:content, {
                \ 'moved': 'any',
                \ })
endfunction

function! util#_create_window(content) abort
    let l:buf_window_id = win_findbuf(s:last_buffer)
    if empty(l:buf_window_id)
        new
        let s:last_buffer = bufnr('%')
        set buftype=nofile
    else
        call win_gotoid(l:buf_window_id[0])
    endif
    call setline(1, content)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
