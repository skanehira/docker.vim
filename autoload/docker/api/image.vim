" docker.vim
" Version: 0.0.1
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

" get images
function! docker#api#image#get() abort
	let l:response = docker#api#http#get("http://localhost/images/json", {})

	if l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
		return []
	endif

	let l:images = []
	for content in json_decode(l:response.content)
		" if repo is null not add to list
		if content.RepoTags is v:null
			continue
		endif

		call add(l:images, content)
	endfor
	return l:images
endfunction

" delte image
function! docker#api#image#delete(id) abort
	echo 'deleting' a:id
	let l:response = docker#api#http#delete("http://localhost/images/" .. a:id, {}, {})
	if l:response.status ==# 404 || l:response.status ==# 409 || l:response.status ==# 500
		call docker#util#echo_err(json_decode(l:response.content).message)
	else
		echo ''
	endif
endfunction

" image pull callback
function! s:image_pull_cb(response) abort
	if a:response.status ==# 200
		echo 'pull image successed'
	else
		call docker#util#echo_err(a:response.content.message)
	endif
endfunction

" pull image
function! docker#api#image#pull(image) abort
	let image_tag = split(a:image, ':')
	if len(image_tag) < 2
		call add(image_tag, 'latest')
	endif

	redraw
	let param = join(image_tag, ":")
	echo "pulling" param

	call docker#api#http#async_post("http://localhost/images/create", 
				\ {'fromImage': param},
				\ {},
				\ function('s:image_pull_cb'),
				\ )
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
