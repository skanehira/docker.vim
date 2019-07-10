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

" get containers
function! docker#api#get_containers() abort
	let l:response = s:docker_http_get('http://localhost/containers/json', {'all': 1})

	if l:response.status ==# 400 || l:response.status ==# 500
		call docker#util#echo_err(l:response.message)
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
		call docker#util#echo_err(l:response.message)
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
		call docker#util#echo_err(l:response.message)
	else
		echo ''
	endif
endfunction

" get images
function! docker#api#get_images() abort
	let l:response = s:docker_http_get("http://localhost/images/json", {})

	if l:response.status ==# 500
		call docker#util#echo_err(l:response.message)
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
