" docker.vim
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

" path separator
let s:sep = fnamemodify('.', ':p')[-1:]

" version info url
let s:version_info_url = 'https://raw.githubusercontent.com/skanehira/docker.vim/develop/docker.version.json'

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

function! s:check_plugin_version_cb(current_info, response) abort
	if a:response.status !=# 200
		call window#util#notification_failed(printf("docker.vim: cannot get latest version info: %s", a:response.content))
		return
	endif

	if type(a:response.content) !=# v:t_dict
		call window#util#notification_failed("docker.vim: cannot get latest version info: invalid response data")
		return
	endif

	if a:current_info.version !=# a:response.content.version
		call window#util#notification_success(printf("docker.vim: there have a new version: %s", a:response.content.version))
	endif
endfunction

" check plugin's version
function! docker#api#version#check_plugin_version() abort
	let data = readfile(expand('<sfile>:p:h') .. s:sep .. 'docker.version.json')
	let current_info = json_decode(join(data, "\n"))
	call docker#api#http#async_get(0,
				\ s:version_info_url,{},
				\ function('s:check_plugin_version_cb', [current_info])
				\ )
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
