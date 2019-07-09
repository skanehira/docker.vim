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
	let l:response = s:HTTP.request(a:url, {
				\ 'unixSocket': '/var/run/docker.sock',
				\ 'param': a:param
				\ })

	if l:response.status != 200
		call docker#util#echo_err(printf("status:%d response:%s", l:response.status, l:response.content))
		return response
	endif

	return json_decode(l:response.content)
endfunction

" http post
function! s:docker_http_post(url, param, data) abort
	let l:response = s:HTTP.request(a:url, {
				\ 'unixSocket': '/var/run/docker.sock',
				\ 'method': 'POST',
				\ 'param': a:param,
				\ 'data' : a:data,
				\ })

	if l:response.status !=# 204 || l:response.status !=# 200
		call docker#util#echo_err(printf("status:%d response:%s", l:response.status, l:response.content))
		return {}
	endif

	if has_key(l:response, 'content')
		return json_decode(l:response.content)
	endif
	return {}
endfunction

" get containers
function! docker#api#get_containers() abort
	return s:docker_http_get('http://localhost/containers/json', {'all': 1})
endfunction

" start container
function! docker#api#start_container(id) abort
	call s:docker_http_post("http://localhost/containers/" .. a:id .. "/start", {}, {})
endfunction

" stop container
function! docker#api#stop_container(id) abort
	call s:docker_http_post("http://localhost/containers/" .. a:id .. "/stop", {}, {})
endfunction

" get images
function! docker#api#get_images() abort
	let l:images = []
	for row in s:docker_http_get("http://localhost/images/json",{})
		" if repo is null not add to list
		if row.RepoTags is v:null
			continue
		endif

		call add(l:images, row)
	endfor
	return l:images
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
