let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')

let s:last_buffer = 0
let s:last_popup_window = 0

if !exists('s:loaded_highlight')
	let s:loaded_highlight = 1
	try
		call prop_type_add('select', {'highlight': 'PmenuSel'})
		call prop_type_add('status_running', {'highlight': 'DiffText', 'priority':1})
	catch /.*/
		call docker#util#echo_err(v:exception)
	endtry
endif

" create popup windows
function! window#util#create_popup_window(ctx) abort
	if !has("patch-8.1.1561")
		call docker#util#echo_err("this version doesn't support popup window. please update version to 8.1.1561")
		return
	endif

	call popup_close(s:last_popup_window)

	let a:ctx.id = popup_create(a:ctx.view_content, {
				\ 'filter': function('s:popup_filter', [a:ctx]),
				\ 'title': a:ctx.title,
				\ 'maxheight': a:ctx.maxheight,
				\ })

	let s:last_popup_window = a:ctx.id
	call s:update_highlight(a:ctx)
endfunction

" update popup window content
function! window#util#update_poup_window(ctx) abort
	let l:win_buf = winbufnr(a:ctx.id)

	if l:win_buf ==# -1
		return
	endif
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
		return 1

	elseif a:key ==# 'j'
		let a:ctx.highlight_idx += a:ctx.highlight_idx ==# len(a:ctx.view_content) -1 ? 0 : 1
		let a:ctx.select += a:ctx.select ==# len(a:ctx.content) -1 ? 0 : 1
		if a:ctx.select >= a:ctx.offset + a:ctx.top
			let a:ctx.offset = a:ctx.select - (a:ctx.top - 1)
			call s:update_view_content(a:ctx)
		endif

	elseif a:key ==# 'k'
		let idx = a:ctx.highlight_idx ==# 4 ? 0 : 1
		let a:ctx.highlight_idx -= idx
		let a:ctx.select -= a:ctx.select ==# 0 ? 0 : 1
		if a:ctx.select < a:ctx.offset
			let a:ctx.offset = a:ctx.select
			call s:update_view_content(a:ctx)
		endif

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
		endif
	endif

	if a:ctx.type == 'container'
		call docker#container#functions(a:ctx, a:key)
		call window#util#update_poup_window(a:ctx)
	elseif a:ctx.type == 'image'
		call docker#image#functions(a:ctx, a:key)
		call window#util#update_poup_window(a:ctx)
	endif

	if a:key != "\<CursorHold>"
		call window#util#update_poup_window(a:ctx)
	endif
	return 1
endfunction

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
					\ 'columns': [{},{},{},{},{},{}],
					\ 'header' : ['ID', 'NAME', 'IMAGE', 'STATUS', 'CREATED', 'PORTS'],
					\ })

		for row in a:ctx.content[a:ctx.offset: a:ctx.offset + a:ctx.top - 1]
			let l:container = docker#util#parse_container(row)
			call l:container_table.add_row([
						\ l:container.Id,
						\ l:container.Name,
						\ l:container.Image,
						\ l:container.Status,
						\ l:container.Created,
						\ l:container.Ports
						\ ])
		endfor
		let a:ctx.view_content = l:container_table.stringify()
	endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
