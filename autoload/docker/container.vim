let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')
let s:table = {}

function! s:get() abort
	let s:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{},{}],
				\ 'header' : ['ID', 'NAME', 'IMAGE', 'STATUS', 'CREATED', 'PORTS'],
				\ })

	let l:containers = []
	for row in docker#util#http_get('http://localhost/containers/json',{'all': 1})
		let l:container = docker#util#parse_container(row)
		call s:table.add_row([
					\ l:container.Id,
					\ l:container.Name,
					\ l:container.Image,
					\ l:container.Status,
					\ l:container.Created,
					\ l:container.Ports
					\ ])
		call add(l:containers, row)
	endfor

	if len(l:containers) ==# 0
		call util#echo_err('no containers')
	endif

	return l:containers
endfunction

" get and popup images
function! docker#container#get() abort
	let l:containers = s:get()
	let l:view_containers = s:table.stringify()
	call window#util#create_popup_window('containers', 'container', l:view_containers, l:containers)
endfunction

function! docker#container#start_monitor(id) abort
	call docker#monitor#start_monitoring(a:id)
endfunction

function! docker#container#stop_monitor() abort
	call docker#monitor#stop_monitoring()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
