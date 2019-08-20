" docker.vim
" Version: 0.2.0
" Author : skanehira <sho19921005@gmail.com>
" License: MIT
"
let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

if exists('g:loaded_docker')
	finish
endif

let g:loaded_docker = 1
" open browser command
let g:docker_open_browser_cmd = 'open'
" see :h vert
let g:docker_terminal_open = 'bo'
" load syntax
exe 'runtime syntax/docker.vim'

command! DockerImages call docker#image#get()
command! DockerContainers call docker#container#get()
command! -nargs=1 DockerMonitorStart call docker#monitor#start(<f-args>)
command! DockerMonitorStop call docker#monitor#stop()
command! DockerMonitorWindowMove call docker#monitor#move()
command! DockerImagePull call docker#image#pull(<f-args>)
command! -nargs=1 DockerContainerLogs call docker#api#container#logs(<f-args>)
command! DockerVersion call docker#version#info()
command! DockerImageSearch call docker#image#search()

let &cpo = s:save_cpo
unlet s:save_cpo
