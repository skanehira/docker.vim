let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')
let s:table = {}

" get container from docker
function! s:get(offset, top) abort
	let s:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{},{}],
				\ 'header' : ['ID', 'NAME', 'IMAGE', 'STATUS', 'CREATED', 'PORTS'],
				\ })

	let l:containers = []
	for row in docker#util#http_get('http://localhost/containers/json',{'all': 1})
		call add(l:containers, row)
	endfor

	if len(l:containers) ==# 0
		call util#echo_err('no containers')
		return []
	endif

	for row in l:containers[a:offset: a:offset + a:top -1]
		let l:container = docker#util#parse_container(row)
		call s:table.add_row([
					\ l:container.Id,
					\ l:container.Name,
					\ l:container.Image,
					\ l:container.Status,
					\ l:container.Created,
					\ l:container.Ports
					\ ])
	endfor

	return l:containers
endfunction

" get and popup images
function! docker#container#get() abort
	" highlight_idx is highlight idx
	" select is selected entry
	let l:maxheight = 15
	let l:top = l:maxheight - 4
	let l:ctx = { 'type': 'container',
				\ 'title':'[containers]',
				\ 'select':0,
				\ 'highlight_idx': 4,
				\ 'content': s:get(0, l:top),
				\ 'view_content': s:table.stringify(),
				\ 'maxheight': l:maxheight,
				\ 'top': l:top,
				\ 'offset': 0}

	call window#util#create_popup_window(l:ctx)
endfunction

function! s:docker_up_container(ctx) abort
	let id = a:ctx.content[a:ctx.select].Id
	call docker#util#post_no_response("http://localhost/containers/" .. id .. "/start", {}, {})
	let a:ctx.content = s:get(0, a:ctx.top)
	let a:ctx.view_content = s:table.stringify()
endfunction

function! s:docker_stop_container(ctx) abort
	let id = a:ctx.content[a:ctx.select].Id
	call docker#util#post_no_response("http://localhost/containers/" .. id .. "/stop", {}, {})
	let a:ctx.content = s:get(0, a:ctx.top)
	let a:ctx.view_content = s:table.stringify()
endfunction

function! docker#container#functions(ctx, key) abort
	let l:entry = a:ctx.content[a:ctx.select]
	if a:key ==# 'u'
		call s:docker_up_container(a:ctx)
	elseif a:key ==# 's'
		call s:docker_stop_container(a:ctx)
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
