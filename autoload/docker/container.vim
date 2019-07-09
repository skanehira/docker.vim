let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')

" get container from docker engine
" return
" {
" 'content': {images},
" 'view_content': {table}'
" }
function! s:container_get(offset, top) abort
	let l:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{},{}],
				\ 'header' : ['ID', 'NAME', 'IMAGE', 'STATUS', 'CREATED', 'PORTS'],
				\ })

	let l:containers = docker#api#get_containers()

	for row in l:containers[a:offset: a:offset + a:top -1]
		let l:container = docker#util#parse_container(row)
		call l:table.add_row([
					\ l:container.Id,
					\ l:container.Name,
					\ l:container.Image,
					\ l:container.Status,
					\ l:container.Created,
					\ l:container.Ports
					\ ])
	endfor

	return {'content': l:containers,
				\ 'view_content': l:table.stringify(),
				\ }
endfunction

" get and popup images
function! docker#container#get() abort
	let l:maxheight = 15
	let l:top = l:maxheight - 4
	let l:contents = s:container_get(0, l:top)
	let l:ctx = { 'type': 'container',
				\ 'title':'[containers]',
				\ 'select':0,
				\ 'highlight_idx': 4,
				\ 'content': l:contents.content,
				\ 'view_content': l:contents.view_content,
				\ 'maxheight': l:maxheight,
				\ 'top': l:top,
				\ 'offset': 0}

	call window#util#create_popup_window(l:ctx)
endfunction

" update contents
function! s:docker_update_contents(ctx) abort
	let l:contents = s:container_get(0, a:ctx.top)
	let a:ctx.content = l:contents.content
	let a:ctx.view_content = l:contents.view_content
endfunction

" start container
function! s:docker_start_container(ctx) abort
	call docker#api#start_container(a:ctx.content[a:ctx.select].Id)
	call s:docker_update_contents(a:ctx)
endfunction

" stop container
function! s:docker_stop_container(ctx) abort
	call docker#api#stop_container(a:ctx.content[a:ctx.select].Id)
	call s:docker_update_contents(a:ctx)
endfunction

function! docker#container#functions(ctx, key) abort
	let l:entry = a:ctx.content[a:ctx.select]
	if a:key ==# 'u'
		call s:docker_start_container(a:ctx)
	elseif a:key ==# 's'
		call s:docker_stop_container(a:ctx)
	elseif a:key ==# 'd'
		" TODO delete container
	elseif a:key ==# 'r'
		" TODO restart container
	elseif a:key ==# 'R'
		" TODO refresh containers
	elseif a:key ==# 'm'
		call popup_close(a:ctx.id)
		call docker#container#start_monitor(l:entry.Id)
	endif
endfunction

function! docker#container#start_monitor(id) abort
	call docker#monitor#start_monitoring(a:id)
endfunction

function! docker#container#stop_monitor() abort
	call docker#monitor#stop_monitoring()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo