let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:DATE = s:V.import('DateTime')
let s:HTTP = s:V.import('Web.HTTP')

let s:last_buffer = 0
let s:last_popup_window = 0

function! util#http_get(url, param) abort
    let l:response = s:HTTP.request(a:url, {
                \ 'unixSocket': '/var/run/docker.sock',
                \ 'param': a:param
                \ })
    if l:response.status != 200
        echoerr printf("status:%d response:%s", l:response.status, l:response.content)
    endif

    return json_decode(l:response.content)
endfunction

function! util#parse_id(id) abort
    return a:id[7:19]
endfunction

function! util#parse_unix_date(date) abort
    return s:DATE.from_unix_time(a:date).format('%F %T')
endfunction

function! util#parse_size(size) abort
    return printf("%.2fMB", a:size / 1024 / 1024.0)
endfunction

function! util#popup_window(content) abort
    call popup_close(s:last_popup_window)
    call popup_create(a:content, {
                \ 'moved': 'any',
                \ })
endfunction

function! util#create_window(content) abort
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
