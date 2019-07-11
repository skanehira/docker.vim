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
function! s:docker_container_get(offset, top) abort
	let l:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{},{}],
				\ 'header' : ['ID', 'NAME', 'IMAGE', 'STATUS', 'CREATED', 'PORTS'],
				\ })

	let l:containers = docker#api#container#get()

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

" get containers and display on popup window
function! docker#container#get() abort
	let l:maxheight = 15
	let l:top = l:maxheight - 4
	let l:contents = s:docker_container_get(0, l:top)
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
	let l:contents = s:docker_container_get(a:ctx.offset, a:ctx.top)
	let a:ctx.content = l:contents.content
	let a:ctx.view_content = l:contents.view_content
endfunction

" start container
function! s:docker_start_container(ctx) abort
	call docker#api#container#start(a:ctx.content[a:ctx.select].Id)
	call s:docker_update_contents(a:ctx)
endfunction

" stop container
function! s:docker_stop_container(ctx) abort
	call docker#api#container#stop(a:ctx.content[a:ctx.select].Id)
	call s:docker_update_contents(a:ctx)
endfunction

" delete container
function! s:docker_delete_container(ctx, id, key) abort
	if a:key ==# -1 || a:key ==# 0
		return
	endif
	call docker#api#container#delete(a:ctx.content[a:ctx.select].Id)
	call s:docker_update_contents(a:ctx)
endfunction

" restart container
function! s:docker_restart_container(ctx) abort
	call docker#api#container#restart(a:ctx.content[a:ctx.select].Id)
	call s:docker_update_contents(a:ctx)
endfunction

" kill container
function! s:docker_kill_container(ctx) abort
	call docker#api#container#kill(a:ctx.content[a:ctx.select].Id)
	call s:docker_update_contents(a:ctx)
endfunction

" this is popup window filter function
function! docker#container#functions(ctx, key) abort
	let l:entry = a:ctx.content[a:ctx.select]
	if a:key ==# 'u'
		call s:docker_start_container(a:ctx)
	elseif a:key ==# 's'
		call s:docker_stop_container(a:ctx)
	elseif a:key ==# 'd'
		call popup_create("Do you delete the container? y/n",{
					\ 'border': [],
					\ 'filter': 'popup_filter_yesno',
					\ 'callback': function('s:docker_delete_container', [a:ctx]),
					\ 'zindex': 51,
					\ })
	elseif a:key ==# 'r'
		call s:docker_restart_container(a:ctx)
	elseif a:key ==# "m"
		call popup_close(a:ctx.id)
		call docker#monitor#start(l:entry.Id)
	elseif a:key ==# 'R'
		call s:docker_update_contents(a:ctx)
	elseif a:key ==# 'a'
		call popup_close(a:ctx.id)
		let cmd = input("command:")
		if cmd ==# ''
			call docker#util#echo_err('please input command')
			call docker#container#get()
			return
		endif
		call docker#api#container#attach(l:entry.Id, cmd)
	elseif a:key ==# 'K'
		call s:docker_kill_container(a:ctx)
	endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
