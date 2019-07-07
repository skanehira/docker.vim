let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:HTTP = s:V.import('Web.HTTP')
let s:DATE = s:V.import('DateTime')

" echo error message
function! docker#util#echo_err(message) abort
	echohl ErrorMsg
	echo a:message
	echohl None
endfunction

" get response from docker
function! docker#util#http_get(url, param) abort
	let l:response = s:HTTP.request(a:url, {
				\ 'unixSocket': '/var/run/docker.sock',
				\ 'param': a:param
				\ })

	if l:response.status != 200
		util#echo_err(printf("status:%d response:%s", l:response.status, l:response.content))
		return response
	endif

	return json_decode(l:response.content)
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
	let l:new_image.Repo = l:repo_tags[0]
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
	let _new.Name = a:container.Names[0][1:][:20] . "..."
	let _new.Image = a:container.Image[:20] . "..."
	let _new.Status = a:container.Status
	let _new.Created = docker#util#parse_unix_date(a:container.Created)
	let _new.Ports = docker#util#parse_container_ports(a:container.Ports)
	let _new.Command = a:container.Command
	return _new
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
