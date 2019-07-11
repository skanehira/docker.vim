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

	if l:response.status ==# 400 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
		return []
	endif

	return json_decode(l:response.content)
endfunction

" start container
function! docker#api#container#start(id) abort
	echo 'starting' a:id
	let l:response = docker#api#http#post("http://localhost/containers/" .. a:id .. "/start", {}, {})
	if l:response.status ==# 304
		echo "container already started"
	elseif l:response.status ==# 404 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" stop container
function! docker#api#container#stop(id) abort
	echo 'stopping' a:id
	let l:response = docker#api#http#post("http://localhost/containers/" .. a:id .. "/stop", {}, {})
	if l:response.status ==# 304
		echo "container already stopped"
	elseif l:response.status ==# 404 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" restart container
function! docker#api#container#restart(id) abort
	echo 'restarting' a:id
	let l:response = docker#api#http#post("http://localhost/containers/" .. a:id .. "/restart", {}, {})
	if l:response.status ==# 404 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" delete container
function! docker#api#container#delete(id) abort
	if docker#api#is_runiing_container(a:id)
		call docker#util#echo_err('the container is running')
		return
	endif
	echo 'deleting' a:id
	let l:response = docker#api#http#delete("http://localhost/containers/" .. a:id, {}, {})
	if l:response.status ==# 404 || l:response.status ==# 500 || l:response.status ==# 409
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" attach to a container using docker command
" TODO use attach api
function! docker#api#container#attach(id, cmd) abort
	if !executable('docker')
		call docker#util#echo_err('not exsists docker command')
		return
	endif
	if !docker#api#container#is_running(a:id)
		call docker#util#echo_err('the container is not running')
		call docker#container#get()
		return
	endif
	exe 'term ++close bash -c "docker exec -it ' .. a:id  .. ' ' .. a:cmd .. '"'
endfunction

" kill container
function! docker#api#container#kill(id) abort
	echo 'killing' a:id
	let l:response = docker#api#http#post("http://localhost/containers/" .. a:id .. "/kill", {}, {})
	if l:response.status ==# 404 || l:response.status ==# 500 || l:response.status ==# 409
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" check the container state
" if the container is running then will return true
function! docker#api#container#is_running(id) abort
	let l:response = docker#api#http#get("http://localhost/containers/" .. a:id .. "/json", {})
	if l:response.status ==# 404 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
	endif
	return json_decode(l:response.content).State.Running
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
