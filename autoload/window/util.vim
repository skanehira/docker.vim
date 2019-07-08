let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')

let s:last_buffer = 0
let s:last_popup_window = 0

if !exists('s:docker_loaded_highlight')
	let s:docker_loaded_highlight = 1
	try
		call prop_type_add('docker_select', {'highlight': 'PmenuSel'})
		call prop_type_add('docker_status_running', {'highlight': 'DiffText'})
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
				\ 'filter': function('s:filter', [a:ctx]),
				\ 'title': a:ctx.title,
				\ 'maxheight': a:ctx.maxheight,
				\ })

	let s:last_popup_window = a:ctx.id
	call s:update_highlight(a:ctx)
endfunction

" update popup window content
function! window#util#update_poup_window(ctx) abort
	call s:docker_update_view_content(a:ctx)
	let l:win_buf = winbufnr(a:ctx.id)

	if l:win_buf ==# -1
		call util#echo_err("no popup window")
		return
	endif
	call win_execute(l:win_buf, '%d_')
	call setbufline(l:win_buf, 1, a:ctx.view_content)
	call s:update_highlight(a:ctx)
endfunction

" create window
function! window#util#create_window(content) abort
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
				\ 'type': 'docker_select',
				\ 'bufnr': l:buf,
				\ })

	call prop_add(l:lnum, 1, {
				\ 'bufnr': l:buf,
				\ 'type': 'docker_select',
				\ 'length': l:length,
				\ })

endfunction

function! s:status_highlight(ctx) abort
	let l:lnum = 4
	let l:lnum_end = len(a:ctx.view_content)
	let l:length = len(a:ctx.view_content[0])
	let l:buf = winbufnr(a:ctx.id)

	call prop_remove({
				\ 'type': 'docker_status_running',
				\ 'bufnr': l:buf,
				\ })

	for content in a:ctx.content[a:ctx.offset:a:ctx.offset + a:ctx.top-1]
		if content.State ==# "running"
			call prop_add(l:lnum, 1, {
						\ 'bufnr': l:buf,
						\ 'type': 'docker_status_running',
						\ 'length': l:length,
						\ })
		endif
		let l:lnum += 1
	endfor
endfunction

function! s:update_highlight(ctx) abort
	call s:select_highlight(a:ctx)
	if a:ctx.type ==# 'container'
		call s:status_highlight(a:ctx)
	endif
	call win_execute(a:ctx.id, 'redraw')
endfunction

" popup window filter
function! s:filter(ctx, id, key) abort
	"let l:buf = winbufnr(a:id)
	let l:entry = a:ctx.content[a:ctx.select]

	if a:key ==# 'q' || a:key ==# 'x'
		call popup_close(a:id)
		return 1
	elseif a:key ==# "\n" || a:key ==# "\r"
		return 1
	elseif a:key ==# 'j'
		let a:ctx.highlight_idx += a:ctx.highlight_idx ==# len(a:ctx.view_content) -1 ? 0 : 1
		let a:ctx.select += a:ctx.select ==# len(a:ctx.content) -1 ? 0 : 1
		if a:ctx.select >= a:ctx.offset + a:ctx.top
			let a:ctx.offset = a:ctx.select - (a:ctx.top - 1)
		endif

	elseif a:key ==# 'k'
		let idx = a:ctx.highlight_idx ==# 4 ? 0 : 1
		let a:ctx.highlight_idx -= idx
		let a:ctx.select -= a:ctx.select ==# 0 ? 0 : 1
		if a:ctx.select < a:ctx.offset
			let a:ctx.offset = a:ctx.select
		endif

	elseif a:key ==# '0'
		let a:ctx.highlight_idx = 4
		let a:ctx.select = 0
		let a:ctx.offset = 0
		let a:ctx.top = a:ctx.maxheight - 4

	elseif a:key ==# 'G'
		let a:ctx.highlight_idx = len(a:ctx.view_content) - 1
		let a:ctx.select = len(a:ctx.content) - 1
		let a:ctx.offset = len(a:ctx.content) - a:ctx.top

	elseif a:key ==# 'm'
		if a:ctx.type == 'container'
			call popup_close(a:id)
			call docker#container#start_monitor(l:entry.Id)
		endif
		return 1
	endif
	call window#util#update_poup_window(a:ctx)
	return 1
endfunction

function! s:docker_update_view_content(ctx) abort
	let idx = 0

	if a:ctx.type ==# 'image'
		let l:image_table = s:TABLE.new({
					\ 'columns': [{},{},{},{},{}],
					\ 'header' : ['ID', 'REPOSITORY', 'TAG', 'CREATED', 'SIZE'],
					\ })

		for row in a:ctx.content[a:ctx.offset:a:ctx.offset + a:ctx.top-1]
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

		for row in a:ctx.content[a:ctx.offset: a:ctx.offset + a:ctx.top -1]
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
