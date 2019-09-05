" docker.vim
" Version: 0.2.1
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

" get containers
function! docker#api#container#get() abort
	let l:response = docker#api#http#get('http://localhost/containers/json', {'all': 1})

	if l:response.status !=# 200
		call window#util#notification_failed(json_decode(l:response.content).message)
		return []
	endif

	return json_decode(l:response.content)
endfunction

" container start callback
function! s:container_start_cb(ctx, updatefunc, response) abort
	if a:response.status ==# 304
		call window#util#notification_success('container is already started')
	elseif a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('started ' .. a:ctx.content[a:ctx.select].Id)
	endif
	call a:updatefunc(a:ctx)
endfunction

" start container
function! docker#api#container#start(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id
	call window#util#notification_normal('starting... ' .. id)
	call docker#api#http#async_post('http://localhost/containers/' .. id .. '/start',
				\ {},
				\ {},
				\ function('s:container_start_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" container stop callback
function! s:container_stop_cb(ctx, updatefunc, response) abort
	if a:response.status ==# 304
		call window#util#notification_success('container is already stopped')
	elseif a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('stopped ' .. a:ctx.content[a:ctx.select].Id)
	endif
	call a:updatefunc(a:ctx)
endfunction

" stop container
function! docker#api#container#stop(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id
	call window#util#notification_normal('stopping... ' .. id)
	call docker#api#http#async_post('http://localhost/containers/' .. id .. '/stop',
				\ {},
				\ {},
				\ function('s:container_stop_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" restart container callback
function! s:container_restart_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('restarted ' .. a:ctx.content[a:ctx.select].Id)
	endif
	call a:updatefunc(a:ctx)
endfunction

" restart container
function! docker#api#container#restart(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id
	call window#util#notification_normal('restaring... ' .. id)
	call docker#api#http#async_post('http://localhost/containers/' .. id .. '/restart',
				\ {},
				\ {},
				\ function('s:container_restart_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" delete container callback
function! s:container_delete_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('deleted ' .. a:ctx.content[a:ctx.select].Id)
	endif

	if a:ctx.select ==# len(a:ctx.content) - 1
		call feedkeys('k')
	endif

	call a:updatefunc(a:ctx)
endfunction

" delete container
function! docker#api#container#delete(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id

	try
		if docker#api#container#is_running(id)
			call window#util#notification_failed('the container is running')
			return
		endif
	catch /.*/
		call window#util#notification_failed(v:exception)
		return
	endtry

	call window#util#notification_normal('deleting... ' .. id)
	call docker#api#http#async_delete('http://localhost/containers/' .. id,
				\ {},
				\ function('s:container_delete_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" attach to a container using docker command
" TODO use attach api
function! docker#api#container#attach(id, cmd) abort
	echo ''
	if !has('terminal')
		call docker#util#echo_err('terminal is not support')
		return
	endif

	if !executable('docker')
		call docker#util#echo_err('no executable command: docker')
		return
	endif

	exe printf('%s term ++close docker exec -it %s %s', g:docker_terminal_open, a:id, a:cmd)
endfunction

function! s:container_kill_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('killed ' .. a:ctx.content[a:ctx.select].Id)
	endif
	call a:updatefunc(a:ctx)
endfunction

" kill container
function! docker#api#container#kill(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id
	call window#util#notification_normal('killing... ' .. id)
	call docker#api#http#async_post("http://localhost/containers/" .. id .. "/kill",
				\ {},
				\ {},
				\ function('s:container_kill_cb', [a:ctx, a:updatefunc]),
				\ )
endfunction

" rename container callback
function! s:container_rename_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('renamed ' .. a:ctx.content[a:ctx.select].Id)
	endif
	call a:updatefunc(a:ctx)
endfunction

" rename container
function! docker#api#container#rename(ctx, name, updatefunc) abort
	echo ''
	let id = a:ctx.content[a:ctx.select].Id
	call window#util#notification_normal(printf('renaming to %s...', a:name))
	call docker#api#http#async_post('http://localhost/containers/' .. id .. '/rename',
				\ {'name': a:name},
				\ {},
				\ function('s:container_rename_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" tail container logs
" if container is not running, terminal does not close automatically
function! docker#api#container#logs(id) abort
	if !has('terminal')
		call window#util#notification_failed('terminal is not support')
		return
	endif

	if !executable('docker')
		call docker#util#echo_err('no executable command: docker')
		return
	endif

	try
		let cmd = ''
		if docker#api#container#is_running(a:id)
			let cmd = printf('bo term ++close docker logs -f %s', a:id)
		else
			let cmd = printf('bo term docker logs -f %s', a:id)
		endif
		exe cmd
		exe "wincmd k"
	catch /.*/
		call window#util#notification_failed(v:exception)
	endtry
endfunction

" check the container state
" if the container is running then will return true
function! docker#api#container#is_running(id) abort
	let l:response = docker#api#http#get('http://localhost/containers/' .. a:id .. '/json', {})
	if l:response.status !=# 200
		throw json_decode(l:response.content).message
	endif
	return json_decode(l:response.content).State.Running
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
