" docker.vim
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

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
function! s:container_get(search_word, offset, top) abort
	let l:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{},{},{}],
				\ 'header' : ['ID', 'NAME', 'IMAGE', 'COMMAND', 'STATUS', 'CREATED', 'PORTS'],
				\ })

	let l:containers = filter(docker#api#container#get(), 'v:val.Names[0][1:] =~ a:search_word[1:]')

	for row in l:containers[a:offset: a:offset + a:top -1]
		let l:container = docker#util#parse_container(row)
		call l:table.add_row([
					\ l:container.Id,
					\ l:container.Name,
					\ l:container.Image,
					\ l:container.Command,
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
	let l:contents = s:container_get('', 0, l:top)

	if len(l:contents.content) ==# 0
		call docker#util#echo_err('there are no containers')
		return
	endif

	let l:ctx = { 'type': 'container',
				\ 'title':'[containers]',
				\ 'select':0,
				\ 'highlight_idx': 4,
				\ 'content': l:contents.content,
				\ 'view_content': l:contents.view_content,
				\ 'maxheight': l:maxheight,
				\ 'top': l:top,
				\ 'offset': 0,
				\ 'disable_filter': 0,
				\ 'refresh_timer': 0,
				\ 'search_word': '',
				\ 'search_mode': 0
				\ }

	call window#util#create_popup_window(l:ctx)

	" update every 5 second
	let ctx.refresh_timer = timer_start(5000,
				\ function('s:update_contents_timer', [ctx]),
				\ {'repeat': -1}
				\ )
endfunction

" update every specified time
function! s:update_contents_timer(ctx, timer) abort
	call docker#container#update_contents(a:ctx)
endfunction

" update contents
function! docker#container#update_contents(ctx) abort
	let l:contents = s:container_get(a:ctx.search_word, a:ctx.offset, a:ctx.top)
	let a:ctx.content = l:contents.content
	let a:ctx.view_content = l:contents.view_content
	call window#util#update_poup_window(a:ctx)
endfunction

" delete container
function! s:delete_container(ctx) abort
	let a:ctx.disable_filter = 1
	let result = input('do you want to delete the container? y/n:')
	let a:ctx.disable_filter = 0
	echo ''

	if result ==# 'y' || result ==# 'Y'
		call docker#api#container#delete(a:ctx, function('docker#container#update_contents'))
	endif
endfunction

" rename container
function! s:rename_container(ctx) abort
	let a:ctx.disable_filter = 1
	let name = input("new container name:")
	let a:ctx.disable_filter = 0
	echo ''

	if name ==# ''
		call docker#util#echo_err('please input container name')
		call docker#container#update_contents(a:ctx)
		return
	endif

	let a:ctx['name'] = name
	call docker#api#container#rename(a:ctx, function('docker#container#update_contents'))
endfunction

" attach container
function! s:attach_container(ctx) abort
	if !docker#util#have_docker_cli()
		return
	endif

	let entry = a:ctx.content[a:ctx.select]
	try
		if !docker#api#container#is_running(entry.Id)
			call docker#util#echo_err('the container is not running')
			call docker#container#update_contents(a:ctx)
			return
		endif
	catch /.*/
		call docker#util#echo_err(v:exception)
		return
	endtry

	let a:ctx.disable_filter = 1
	let cmd = input("execute command:")
	let a:ctx.disable_filter = 0
	echo ''

	if cmd ==# ''
		call docker#util#echo_err('please input command')
		call docker#container#update_contents(a:ctx)
		return
	endif

	call popup_close(a:ctx.id)
	call docker#api#container#attach(entry.Names[0], cmd)
endfunction

" this is popup window filter function
function! docker#container#functions(ctx, key) abort
	if a:key ==# 'u'
		call docker#api#container#start(a:ctx, function('docker#container#update_contents'))
	elseif a:key ==# 's'
		call docker#api#container#stop(a:ctx, function('docker#container#update_contents'))
	elseif a:key ==# "\<C-d>"
		call s:delete_container(a:ctx)
	elseif a:key ==# 'r'
		call docker#api#container#restart(a:ctx, function('docker#container#update_contents'))
	elseif a:key ==# "m"
		call popup_close(a:ctx.id)
		call docker#monitor#start(a:ctx.content[a:ctx.select].Id)
	elseif a:key ==# 'R'
		call docker#container#update_contents(a:ctx)
	elseif a:key ==# "\<C-r>"
		call s:rename_container(a:ctx)
	elseif a:key ==# 'a'
		call s:attach_container(a:ctx)
	elseif a:key ==# 'K'
		call docker#api#container#kill(a:ctx, function('docker#container#update_contents'))
	elseif a:key ==# 'l'
		call popup_close(a:ctx.id)
		call docker#api#container#logs(a:ctx.content[a:ctx.select])
	endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
