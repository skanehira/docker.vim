" docker.vim
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')

let s:last_buffer = 0
let s:last_popup_window = 0
let s:last_notification_window = 0

if !exists('s:loaded_highlight')
	let s:loaded_highlight = 1
	try
		call prop_type_add('select', {'highlight': 'PmenuSel', 'priority':1})
		call prop_type_add('status_running', {'highlight': 'DiffText'})
	catch /.*/
		call docker#util#echo_err(v:exception)
	endtry
endif

" poup window close callback
function! s:popup_window_close_cb(ctx, id, result) abort
	call timer_stop(a:ctx.refresh_timer)
endfunction

" create popup windows
function! window#util#create_popup_window(ctx) abort
	if !has("patch-8.1.1799")
		call docker#util#echo_err("this version doesn't support popup window. please update version to 8.1.1799 or above")
		return
	endif

	call popup_close(s:last_popup_window)

	let a:ctx.id = popup_create(a:ctx.view_content, {
				\ 'filter': function('s:popup_filter', [a:ctx]),
				\ 'title': a:ctx.title,
				\ 'maxheight': a:ctx.maxheight,
				\ 'callback': function('s:popup_window_close_cb', [a:ctx]),
				\ 'mapping': 0,
				\ })

	let s:last_popup_window = a:ctx.id
	call s:update_highlight(a:ctx)
endfunction

" update popup window content
function! window#util#update_poup_window(ctx) abort
	call popup_settext(a:ctx.id, a:ctx.view_content)
	call s:update_highlight(a:ctx)
endfunction

" create buffer window
" TODO support buffer window
function! window#util#create_buffer_window(content) abort
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
function! s:select_highlight(ctx) abort
	let l:buf = winbufnr(a:ctx.id)
	if l:buf ==# -1
		return
	endif

	let l:length = len(a:ctx.view_content[0])
	let l:lnum = a:ctx.highlight_idx

	call prop_remove({
				\ 'type': 'select',
				\ 'bufnr': l:buf,
				\ })

	call prop_add(l:lnum, 1, {
				\ 'bufnr': l:buf,
				\ 'type': 'select',
				\ 'length': l:length,
				\ })

endfunction

" highlight running container
function! s:status_highlight(ctx) abort
	let l:lnum = 4
	let l:lnum_end = len(a:ctx.view_content)
	let l:length = len(a:ctx.view_content[0])
	let l:buf = winbufnr(a:ctx.id)
	if l:buf ==# -1
		return
	endif

	call prop_remove({
				\ 'type': 'status_running',
				\ 'bufnr': l:buf,
				\ })

	for content in a:ctx.content[a:ctx.offset:a:ctx.offset + a:ctx.top-1]
		if content.State ==# "running"
			call prop_add(l:lnum, 1, {
						\ 'bufnr': l:buf,
						\ 'type': 'status_running',
						\ 'length': l:length,
						\ })
		endif
		let l:lnum += 1
	endfor
endfunction

" update table highlight
function! s:update_highlight(ctx) abort
	if len(a:ctx.content) ==# 0 || len(a:ctx.content) < a:ctx.select
		return
	endif

	call s:select_highlight(a:ctx)
	if a:ctx.type ==# 'container'
		call s:status_highlight(a:ctx)
	endif
	call win_execute(a:ctx.id, 'redraw')
endfunction

" popup window filter
function! s:popup_filter(ctx, id, key) abort
	if a:ctx.disable_filter
		return 0
	endif

	if a:key ==# 'q' || a:key ==# 'x'
		call popup_close(a:id)
		call timer_stop(a:ctx.refresh_timer)
		return 1

	elseif a:key ==# 'j'
		let a:ctx.highlight_idx += a:ctx.highlight_idx ==# len(a:ctx.view_content) -1 ? 0 : 1
		let a:ctx.select += a:ctx.select ==# len(a:ctx.content) -1 ? 0 : 1
		if a:ctx.select >= a:ctx.offset + a:ctx.top
			let a:ctx.offset = a:ctx.select - (a:ctx.top - 1)
			call s:update_view_content(a:ctx)
		else
			call s:update_highlight(a:ctx)
		endif

	elseif a:key ==# 'k'
		let idx = a:ctx.highlight_idx ==# 4 ? 0 : 1
		let a:ctx.highlight_idx -= idx
		let a:ctx.select -= a:ctx.select ==# 0 ? 0 : 1
		if a:ctx.select < a:ctx.offset
			let a:ctx.offset = a:ctx.select
			call s:update_view_content(a:ctx)
		else
			call s:update_highlight(a:ctx)
		endif

		call window#util#update_poup_window(a:ctx)
	elseif a:key ==# '0'
		let a:ctx.highlight_idx = 4
		let a:ctx.select = 0
		let a:ctx.offset = 0
		let a:ctx.top = a:ctx.maxheight - 4
		call s:update_view_content(a:ctx)
	elseif a:key ==# 'G'
		let a:ctx.highlight_idx = len(a:ctx.view_content) - 1
		let a:ctx.select = len(a:ctx.content) - 1
		if len(a:ctx.content) > a:ctx.top
			let a:ctx.offset = len(a:ctx.content) - a:ctx.top
			call s:update_view_content(a:ctx)
		else
			call s:update_highlight(a:ctx)
		endif
	endif

	if a:ctx.type == 'container'
		call docker#container#functions(a:ctx, a:key)
	elseif a:ctx.type == 'image'
		call docker#image#functions(a:ctx, a:key)
	elseif a:ctx.type == 'search'
		if a:key ==# 'p'
			call popup_close(a:id)
			call docker#api#image#pull(a:ctx.content[a:ctx.select].name)
		elseif a:key ==# 'o'
			call docker#util#open_docker_hub(a:ctx.content[a:ctx.select])
		endif
	endif

	redraw

	return 1
endfunction

" this functions is only update table contents
" doesn't get data from docker engine
function! s:update_view_content(ctx) abort
	if a:ctx.type ==# 'image'
		let l:image_table = s:TABLE.new({
					\ 'columns': [{},{},{},{},{}],
					\ 'header' : ['ID', 'REPOSITORY', 'TAG', 'CREATED', 'SIZE'],
					\ })

		for row in a:ctx.content[a:ctx.offset:a:ctx.offset + a:ctx.top - 1]
			let l:image = docker#util#parse_image(row)

			call l:image_table.add_row([
						\ l:image.Id,
						\ l:image.Repo,
						\ l:image.Tag,
						\ l:image.Created,
						\ l:image.Size])
		endfor

		let a:ctx.view_content = l:image_table.stringify()
	elseif a:ctx.type ==# 'container'
		let l:container_table = s:TABLE.new({
					\ 'columns': [{},{},{},{},{},{},{}],
					\ 'header' : ['ID', 'NAME', 'IMAGE', 'COMMAND', 'STATUS', 'CREATED', 'PORTS'],
					\ })

		for row in a:ctx.content[a:ctx.offset: a:ctx.offset + a:ctx.top - 1]
			let l:container = docker#util#parse_container(row)
			call l:container_table.add_row([
						\ l:container.Id,
						\ l:container.Name,
						\ l:container.Image,
						\ l:container.Command,
						\ l:container.Status,
						\ l:container.Created,
						\ l:container.Ports
						\ ])
		endfor
		let a:ctx.view_content = l:container_table.stringify()
	elseif a:ctx.type ==# 'search'
		let l:search_table = s:TABLE.new({
					\ 'columns': [{},{},{},{},{}],
					\ 'header' : ['NAME',  'DESCRIPTION', 'STARS', 'OFFICIAL', 'AUTOMATED'],
					\ })

		for image in a:ctx.content[a:ctx.offset: a:ctx.offset + a:ctx.top - 1]
			call l:search_table.add_row([
						\ image.name,
						\ image.description,
						\ image.stars,
						\ image.official,
						\ image.automated])
		endfor
		let a:ctx.view_content = l:search_table.stringify()
	endif
	call window#util#update_poup_window(a:ctx)
endfunction

" notification some message
" this window does not close automatically
function! window#util#notification_normal(text) abort
	return window#util#notification(a:text, 'normal')
endfunction

" notification error message
" when cursor moved then window will close
function! window#util#notification_failed(text) abort
	return window#util#notification(a:text, 'failed')
endfunction

" notification success message
" this window does close automatically
function! window#util#notification_success(text) abort
	return window#util#notification(a:text, 'success')
endfunction

" popup notification
" type is as below
"  - 'success' is highlight the light blue
"  - 'failed' is highlight the red
"  - 'normal' is highlight the blue
function! window#util#notification(text, type) abort
	call popup_close(s:last_notification_window)

	let option = {
				\ 'highlight': 'notification_normal',
				\ 'col': 1,
				\ 'line': 3,
				\ 'minwidth': 20,
				\ 'tabpage': -1,
				\ 'zindex': 300,
				\ 'drag': 1,
				\ 'border': [1, 1, 1, 1],
				\ 'borderchars': ['-','|','-','|','+','+','+','+']
				\ }

	if a:type ==# 'success'
		let option.highlight = 'notification_success'
		let option['time'] = 3000
	elseif a:type ==# 'failed'
		let option.highlight = 'notification_failed'
		let option['moved'] = 'any'
	endif

	let s:last_notification_window = popup_create(a:text, option)
	call win_execute(s:last_notification_window, 'setfiletype docker')

	" move notification window
	call timer_start(10,
				\ function('s:move_notification'),
				\ {'repeat': 5}
				\ )
endfunction

" move notification window
function! s:move_notification(timer) abort
	let opt = popup_getpos(s:last_notification_window)
	if type(opt) !=# type({}) || empty(opt)
		call docker#util#echo_err('cannot get notification window position')
		call timer_stopall(a:timer)
		return
	endif

	let opt.col += 2
	call popup_move(s:last_notification_window, opt)
	redraw
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
