" docker.vim
" Author : skanehira <sho19921005@gmail.com>
" License: MIT
"
let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

if exists('g:loaded_docker') || has('nvim') || !executable('curl')
	finish
endif

let g:loaded_docker = 1

" open browser command
if !exists('g:docker_open_browser_cmd')
	let g:docker_open_browser_cmd = 'open'
endif

" open terminla way
if !exists('g:docker_terminal_open')
	let g:docker_terminal_open = 'bo'
endif

" check plugins's version
if get(g:, 'docker_plugin_version_check', 1)
	call docker#api#version#check_plugin_version()
endif

" load syntax
exe 'runtime syntax/docker.vim'

command! DockerImages call docker#image#get()
command! DockerImagePull call docker#image#pull(<f-args>)
command! DockerImageSearch call docker#image#search()
command! DockerContainers call docker#container#get()
command! -nargs=1 DockerMonitorStart call docker#monitor#start(<f-args>)
command! DockerMonitorStop call docker#monitor#stop()
command! DockerMonitorWindowMove call docker#monitor#move()
command! -nargs=1 DockerContainerLogs call docker#api#container#logs(<f-args>)
command! DockerVersion call docker#version#info()
command! -nargs=+ Docker call docker#docker#execute(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
