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

let &cpo = s:save_cpo
unlet s:save_cpo
