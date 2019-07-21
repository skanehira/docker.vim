" docker.vim
" Version: 0.2.1
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

" get docker version info
function! docker#api#version#info() abort
	let l:response = docker#api#http#get("http://localhost/version", {})

	if l:response.status !=# 200
		call docker#util#echo_err(json_decode(l:response.content).message)
		return []
	endif

	let info = json_decode(l:response.content)

	let l:infos = []
	call add(l:infos, {'item' :'Platform', 'value': info.Platform.Name})
	call add(l:infos, {'item' :'Version', 'value': info.Version})
	call add(l:infos, {'item' :'API version', 'value': info.ApiVersion})
	call add(l:infos, {'item' :'OS', 'value': printf('%s %s', info.Os, info.Arch)})
	call add(l:infos, {'item' :'Kernel version', 'value': info.KernelVersion})

	return l:infos
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
