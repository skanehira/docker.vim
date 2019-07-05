let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:DATE = s:V.import('DateTime')
let s:HTTP = s:V.import('Web.HTTP')

let s:last_buffer = 0
let s:last_popup_window = 0

if !exists('g:loaded_select_highlight')
	let g:loaded_select_highlight = 1
	try
		call prop_type_add('select', {'highlight': 'CursorLine'})
	catch /.*/
		call util#echo_err(v:exception)
	endtry 
endif

" echo error message
function! util#echo_err(message) abort
	echohl ErrorMsg
	echo a:message
	echohl None
endfunction

" get response from docker
function! util#http_get(url, param) abort
	let l:response = s:HTTP.request(a:url, {
				\ 'unixSocket': '/var/run/docker.sock',
				\ 'param': a:param
				\ })
	if l:response.status != 200
		echoerr printf("status:%d response:%s", l:response.status, l:response.content)
		return {}
	endif

	return json_decode(l:response.content)
endfunction

" prase unix date
function! util#parse_unix_date(date) abort
	return s:DATE.from_unix_time(a:date).format('%F %T')
endfunction

" parse size
function! util#parse_size(size) abort
	return printf("%.2fMB", a:size / 1024 / 1024.0)
endfunction

" create popup windows
function! util#create_popup_window(view_content, content) abort
	if !has("patch-8.1.1561")
		echoerr printf("this version doesn't support popup window. please update version to 8.1.1561")
		return
	endif

	call popup_close(s:last_popup_window)

	" idx is highlight idx
	" select is selected entry
	let l:ctx = {'select':0, 'idx': 4, 'content': a:content, 'view_content': a:view_content, 'maxheight': 15, 'offset': 4}

	let l:ctx.id = popup_create(a:view_content, {
				\ 'filter': function('s:filter', [l:ctx]),
				"\ 'maxheight': l:ctx.maxheight,
				\ })

	call s:highlight(l:ctx)
endfunction

" update popup window content
function! util#update_poup_window(content) abort
	let l:win_buf = winbufnr(s:last_popup_window)

	if l:win_buf ==# -1
		echo util#echo_err("no popup window")
		return
	endif

	call win_execute(s:last_popup_window, '%d_')
	call setbufline(l:win_buf, a:content)
endfunction

" create window
function! util#create_window(content) abort
	let l:buf_window_id = win_findbuf(s:last_buffer)
	if empty(l:buf_window_id)
		new
		let s:last_buffer = bufnr('%')
		set buftype=nofile
	else
		call win_gotoid(l:buf_window_id[0])
	endif
	%d _
	call setline(1, a:content)
endfunction

" highlight table in popup window
function! s:highlight(ctx) abort
	let l:buf = winbufnr(a:ctx.id)
	let l:length = len(a:ctx.view_content[a:ctx.select])
	let l:lnum = a:ctx.idx
	let l:lnum_end = len(a:ctx.view_content)

	call prop_clear(1, l:lnum_end, {
				\ 'bufnr': l:buf,
				\ })

	call prop_add(l:lnum, 1, {
				\ 'bufnr': l:buf,
				\ 'type': 'select',
				\ 'length': l:length,
				\ })

	call win_execute(a:ctx.id, 'redraw')
endfunction

" popup window filter
function! s:filter(ctx, id, key) abort
	let l:buf = winbufnr(a:id)
	let l:entry = a:ctx.content[a:ctx.select]

	if a:key ==# 'q' || a:key ==# 'x'
		call popup_close(a:id)
		return 1
	elseif a:key ==# "\n" || a:key ==# "\r"
		echo l:entry
		return 1
	elseif a:key ==# 'j'
		let idx = a:ctx.idx ==# len(a:ctx.view_content) -1 ? 0 : 1
		let a:ctx.idx += idx
		let a:ctx.select += idx
	elseif a:key ==# 'k'
		let idx = a:ctx.idx ==# 4 ? 0 : 1
		let a:ctx.idx -= idx
		let a:ctx.select -= idx
	elseif a:key ==# '0'
		let a:ctx.idx = 4
		let a:ctx.select = 0
	elseif a:key ==# 'G'
		let a:ctx.idx = len(a:ctx.view_content) -1
		let a:ctx.select = len(a:ctx.content) -1
	endif
	call s:highlight(a:ctx)
	return 1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
