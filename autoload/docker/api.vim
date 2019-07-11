" docker.vim
" Version: 0.0.1
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:HTTP = s:V.import('Web.HTTP')

" http get
function! s:docker_http_get(url, param) abort
	return s:HTTP.request(a:url, {
				\ 'unixSocket': '/var/run/docker.sock',
				\ 'param': a:param
				\ })
endfunction

" http post
function! s:docker_http_post(url, param, data) abort
	return s:HTTP.request(a:url, {
				\ 'unixSocket': '/var/run/docker.sock',
				\ 'method': 'POST',
				\ 'param': a:param,
				\ 'data' : a:data,
				\ })
endfunction

" http post
function! s:docker_http_delete(url, param, data) abort
	return s:HTTP.request(a:url, {
				\ 'unixSocket': '/var/run/docker.sock',
				\ 'method': 'DELETE',
				\ 'param': a:param,
				\ 'data' : a:data,
				\ })
endfunction

" get containers
function! docker#api#get_containers() abort
	let l:response = s:docker_http_get('http://localhost/containers/json', {'all': 1})

	if l:response.status ==# 400 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
		return []
	endif

	return json_decode(l:response.content)
endfunction

" start container
function! docker#api#start_container(id) abort
	echo 'starting' a:id
	let l:response = s:docker_http_post("http://localhost/containers/" .. a:id .. "/start", {}, {})
	if l:response.status ==# 304
		echo "container already started"
	elseif l:response.status ==# 404 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" stop container
function! docker#api#stop_container(id) abort
	echo 'stopping' a:id
	let l:response = s:docker_http_post("http://localhost/containers/" .. a:id .. "/stop", {}, {})
	if l:response.status ==# 304
		echo "container already stopped"
	elseif l:response.status ==# 404 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" restart container
function! docker#api#restart_container(id) abort
	echo 'restarting' a:id
	let l:response = s:docker_http_post("http://localhost/containers/" .. a:id .. "/restart", {}, {})
	if l:response.status ==# 404 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" delete container
function! docker#api#delete_container(id) abort
	if docker#api#is_runiing_container(a:id)
		call docker#util#echo_err('the container is running')
		return
	endif
	echo 'deleting' a:id
	let l:response = s:docker_http_delete("http://localhost/containers/" .. a:id, {}, {})
	if l:response.status ==# 404 || l:response.status ==# 500 || l:response.status ==# 409
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" attach to a container using docker command
" TODO use attach api
function! docker#api#attach_container(id, cmd) abort
	if !executable('docker')
		call docker#util#echo_err('not exsists docker command')
		return
	endif
	if !docker#api#is_runiing_container(a:id)
		call docker#util#echo_err('the container is not running')
		return
	endif
	let command = 'term ++close bash -c "docker exec -it ' .. a:id  .. ' ' .. a:cmd .. '"'
	exe command
endfunction

" kill container
function! docker#api#kill_container(id) abort
	echo 'killing' a:id
	let l:response = s:docker_http_post("http://localhost/containers/" .. a:id .. "/kill", {}, {})
	if l:response.status ==# 404 || l:response.status ==# 500 || l:response.status ==# 409
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" check the container state
" if the container is running then will return true
function! docker#api#is_runiing_container(id) abort
	let l:response = s:docker_http_get("http://localhost/containers/" .. a:id .. "/json", {})
	if l:response.status ==# 404 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
	endif
	return json_decode(l:response.content).State.Running
endfunction

" get images
function! docker#api#get_images() abort
	let l:response = s:docker_http_get("http://localhost/images/json", {})

	if l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
		return []
	endif

	let l:images = []
	for content in json_decode(l:response.content)
		" if repo is null not add to list
		if row.RepoTags is v:null
			continue
		endif

		call add(l:images, content)
	endfor
	return l:images
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
