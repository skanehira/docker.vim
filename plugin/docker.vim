" Version: 0.0.1
" Author : skanehira <sho19921005@gmail.com>
" License: MIT
let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

if exists('g:loaded_docker')
	finish
endif

let g:loaded_docker = 1

command! DockerImages call docker#image#get()
command! DockerContainers call docker#container#get()
command! -nargs=1 DockerMonitorStart call docker#monitor#start(<f-args>)
command! DockerMonitorStop call docker#monitor#stop()
command! DockerMonitorWindowMove call docker#monitor#move()
command! DockerImagePull call docker#image#pull(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
