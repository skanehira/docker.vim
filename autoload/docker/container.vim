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
	let l:contents = s:container_get(0, l:top)
	let l:ctx = { 'type': 'container',
				\ 'title':'[containers]',
				\ 'select':0,
				\ 'highlight_idx': 4,
				\ 'content': l:contents.content,
				\ 'view_content': l:contents.view_content,
				\ 'maxheight': l:maxheight,
				\ 'top': l:top,
				\ 'offset': 0,
				\ 'disable_filter': 0}

	call window#util#create_popup_window(l:ctx)
endfunction

" update contents
function! s:update_contents(ctx) abort
	let l:contents = s:container_get(a:ctx.offset, a:ctx.top)
	let a:ctx.content = l:contents.content
	let a:ctx.view_content = l:contents.view_content
endfunction

" delete container
function! s:delete_container(ctx) abort
	let a:ctx.disable_filter = 1
	let result = input('Do you delete the container? y/n:')

	if result ==# 'y' || result ==# 'Y'
		call docker#api#container#delete(a:ctx, function('s:update_contents'))
	else
		let a:ctx.disable_filter = 0
		echo ''
		redraw
	endif
endfunction

" rename container
function! s:rename_container(ctx) abort
	let a:ctx.disable_filter = 1
	let name = input("new name:")
	if name ==# ''
		call docker#util#echo_err('please input container name')
		let a:ctx.disable_filter = 0
		call s:update_contents(a:ctx)
		return
	endif

	call docker#api#container#rename(a:ctx, name, function('s:update_contents'))
endfunction

" attach container
function! s:attach_container(ctx) abort
	let a:ctx.disable_filter = 1
	let cmd = input("command:")
	if cmd ==# ''
		call docker#util#echo_err('please input command')
		call s:update_contents(a:ctx)
		let a:ctx.disable_filter = 0
		return
	endif

	if !executable('docker')
		call docker#util#echo_err('not exsists docker command')
		let a:ctx.disable_filter = 0
		return
	endif

	let id = a:ctx.content[a:ctx.select].Id
	try
		if !docker#api#container#is_running(id)
			call docker#util#echo_err('the container is not running')
			call s:update_contents(a:ctx)
			let a:ctx.disable_filter = 0
			return
		endif
	catch /.*/
		call docker#util#echo_err(v:exception)
		let a:ctx.disable_filter = 0
		return
	endtry

	call popup_close(a:ctx.id)
	call docker#api#container#attach(id, cmd)
endfunction

" this is popup window filter function
function! docker#container#functions(ctx, key) abort
	if a:key ==# 'u'
		call docker#api#container#start(a:ctx, function('s:update_contents'))
	elseif a:key ==# 's'
		call docker#api#container#stop(a:ctx, function('s:update_contents'))
	elseif a:key ==# ''
		call s:delete_container(a:ctx)
	elseif a:key ==# 'r'
		call docker#api#container#restart(a:ctx, function('s:update_contents'))
	elseif a:key ==# "m"
		call popup_close(a:ctx.id)
		call docker#monitor#start(a:ctx.content[a:ctx.select].Id)
	elseif a:key ==# 'R'
		call s:update_contents(a:ctx)
	elseif a:key ==# ''
		call s:rename_container(a:ctx)
	elseif a:key ==# 'a'
		call s:attach_container(a:ctx)
	elseif a:key ==# 'K'
		call docker#api#container#kill(a:ctx, function('s:update_contents'))
	elseif a:key ==# 'l'
		call popup_close(a:ctx.id)
		call docker#api#container#logs(a:ctx.content[a:ctx.select].Id)
	endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
