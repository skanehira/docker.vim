" docker.vim
" Version: 0.0.1
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

" get containers
function! docker#api#container#get() abort
	let l:response = docker#api#http#get('http://localhost/containers/json', {'all': 1})

	if l:response.status !=# 200
		call docker#util#echo_err(json_decode(l:response.content).message)
		return []
	endif

	return json_decode(l:response.content)
endfunction

" container start callback
function! s:container_start_cb(ctx, updatefunc, response) abort
	if a:response.status ==# 304
		echo "container already started"
	elseif a:response.status !=# 204
		call docker#util#echo_err(a:response.content.message)
	else
		echo ''
	endif
	call a:updatefunc(a:ctx)
endfunction

" start container
function! docker#api#container#start(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id
	echo 'starting' id
	call docker#api#http#async_post("http://localhost/containers/" .. id .. "/start", 
				\ {},
				\ {},
				\ function('s:container_start_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" container stop callback
function! s:container_stop_cb(ctx, updatefunc, response) abort
	if a:response.status ==# 304
		echo "container already stopped"
	elseif a:response.status !=# 204
		call docker#util#echo_err(a:response.content.message)
	else
		echo ''
	endif
	call a:updatefunc(a:ctx)
endfunction

" stop container
function! docker#api#container#stop(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id
	echo 'stopping' id
	call docker#api#http#async_post("http://localhost/containers/" .. id .. "/stop",
				\ {},
				\ {},
				\ function('s:container_stop_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" restart container callback
function! s:container_restart_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call docker#util#echo_err(a:response.content.message)
	else
		echo ''
	endif
	call a:updatefunc(a:ctx)
endfunction

" restart container
function! docker#api#container#restart(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id
	echo 'restarting' id
	call docker#api#http#async_post("http://localhost/containers/" .. id .. "/restart",
				\ {},
				\ {},
				\ function('s:container_restart_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" delete container callback
function! s:container_delete_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call docker#util#echo_err(a:response.content.message)
	endif

	call a:updatefunc(a:ctx)
	let a:ctx.disable_filter = 0
endfunction

" delete container
function! docker#api#container#delete(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id

	try
		if docker#api#container#is_running(id)
			call docker#util#echo_err('the container is running')
			let a:ctx.disable_filter = 0
			return
		endif
	catch /.*/
		let a:ctx.disable_filter = 0
		call docker#util#echo_err(v:exception)
		return
	endtry

	echo 'deleting' id
	redraw

	call docker#api#http#async_delete("http://localhost/containers/" .. id, 
				\ {}, 
				\ function('s:container_delete_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" attach to a container using docker command
" TODO use attach api
function! docker#api#container#attach(id, cmd) abort
	if !has('terminal')
		call docker#util#echo_err('terminal is not support')
		return
	endif
	exe printf('term ++close bash -c "docker exec -it %s %s"', a:id, a:cmd)
endfunction

function! s:container_kill_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call docker#util#echo_err(a:response.content.message)
	else
		echo ''
	endif
	call a:updatefunc(a:ctx)
endfunction

" kill container
function! docker#api#container#kill(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id
	echo 'killing' id
	call docker#api#http#async_post("http://localhost/containers/" .. id .. "/kill", 
				\ {}, 
				\ {},
				\ function('s:container_kill_cb', [a:ctx, a:updatefunc]),
				\ )
endfunction

" rename container callback
function! s:container_rename(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call docker#util#echo_err(a:response.content.message)
	else
		echo ''
	endif
	let a:ctx.disable_filter = 0
	call a:updatefunc(a:ctx)
endfunction

" rename container
function! docker#api#container#rename(ctx, name, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id
	echo 'renaming to' a:name
	call docker#api#http#async_post("http://localhost/containers/" .. id .. "/rename",
				\ {'name': a:name},
				\ {},
				\ function('s:container_rename', [a:ctx, a:updatefunc])
				\ )
endfunction

" check the container state
" if the container is running then will return true
function! docker#api#container#is_running(id) abort
	let l:response = docker#api#http#get("http://localhost/containers/" .. a:id .. "/json", {})
	if l:response.status !=# 200
		throw json_decode(l:response.content).message
	endif
	return json_decode(l:response.content).State.Running
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
