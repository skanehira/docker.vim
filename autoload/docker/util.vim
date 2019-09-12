" docker.vim
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:DATE = s:V.import('DateTime')
let s:docker_hub_url = 'https://hub.docker.com/'

" echo error message
function! docker#util#echo_err(message) abort
	echohl ErrorMsg
	echo a:message
	echohl None
endfunction

" prase unix date
function! docker#util#parse_unix_date(date) abort
	return s:DATE.from_unix_time(a:date).format('%F %T')
endfunction

" parse size
function! docker#util#parse_size(size) abort
	return printf("%.2fMB", a:size / 1024 / 1024.0)
endfunction

" parse image id
function! docker#util#parse_image_id(id) abort
	return a:id[7:19]
endfunction

" parse image
function! docker#util#parse_image(image) abort
	let l:repo_tags = split(a:image.RepoTags[0], ':')
	let l:new_image = {}
	let repo = l:repo_tags[0]
	let l:new_image.Repo = len(repo) > 20 ? repo[:20] .. '...' : repo
	let l:new_image.Tag = l:repo_tags[1]
	let l:new_image.Id = docker#util#parse_image_id(a:image.Id)
	let l:new_image.Created = docker#util#parse_unix_date(a:image.Created)
	let l:new_image.Size = docker#util#parse_size(a:image.Size)

	return l:new_image
endfunction

" parse container id
function! docker#util#parse_container_id(id) abort
	return a:id[0:11]
endfunction

" parse container ports
function! docker#util#parse_container_ports(ports) abort
	let _port = ""
	for port in a:ports
		if !has_key(port, 'PublicPort')
			let _port .= printf("%d/%s ", port.PrivatePort, port.Type)
		else
			let _port .= printf("%s:%d->%d/%s ", port.IP, port.PrivatePort, port.PublicPort, port.Type)
		endif
	endfor
	return _port
endfunction

" parse container
function! docker#util#parse_container(container) abort
	let _new = {}
	let _new.Id = docker#util#parse_container_id(a:container.Id)
	let name = a:container.Names[0][1:]
	let _new.Name = len(name) > 20 ? name[:20] .. "..." : name
	let image = a:container.Image[:20]
	let _new.Image =  len(image) > 20 ? image[:20] .. "..." : image
	let status = a:container.Status
	let _new.Status =  len(status) > 18 ? status[:18] .. "..." : status
	let _new.Created = docker#util#parse_unix_date(a:container.Created)
	let _new.Ports = docker#util#parse_container_ports(a:container.Ports)
	let _new.Command = len(a:container.Command) > 18 ? a:container.Command[:18] .. "..." : a:container.Command
	return _new
endfunction

" open docker hub in browser
function! docker#util#open_docker_hub(image) abort
	if !executable(g:docker_open_browser_cmd)
		call docker#util#echo_err('there are no executable command: ' .. g:docker_open_browser_cmd)
		return
	endif

	let s:url = s:docker_hub_url
	if a:image.official ==# '[OK]'
		let s:url = s:url .. '_/'
	else
		let s:url = s:url .. 'r/'
	endif

	let s:url = s:url .. a:image.name
	call job_start(printf('%s %s', g:docker_open_browser_cmd, s:url))
endfunction

function! docker#util#have_docker_cli() abort
	if !executable('docker')
		call docker#util#echo_err('docker.vim: not found docker cli, please refer to https://docs.docker.com/install/ to install')
		return 0
	endif
	return 1
endfunction

function! docker#util#have_terminal() abort
	if !has('terminal')
		call docker#util#echo_err('docer.vim: this vim doesn''t support terminal')
		return 0
	endif
	return 1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
