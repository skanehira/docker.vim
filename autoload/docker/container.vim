let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')
let s:table = {}

" get container from docker
function! s:get(offset, top) abort
	let s:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{},{}],
				\ 'header' : ['ID', 'NAME', 'IMAGE', 'STATUS', 'CREATED', 'PORTS'],
				\ })

	let l:containers = []
	for row in docker#util#http_get('http://localhost/containers/json',{'all': 1})
		call add(l:containers, row)
	endfor

	if len(l:containers) ==# 0
		call util#echo_err('no containers')
		return []
	endif

	for row in l:containers[a:offset: a:offset + a:top -1]
		let l:container = docker#util#parse_container(row)
		call s:table.add_row([
					\ l:container.Id,
					\ l:container.Name,
					\ l:container.Image,
					\ l:container.Status,
					\ l:container.Created,
					\ l:container.Ports
					\ ])
	endfor

	return l:containers
endfunction

" get and popup images
function! docker#container#get() abort
	" highlight_idx is highlight idx
	" select is selected entry
	let l:maxheight = 15
	let l:top = l:maxheight - 4
	let l:ctx = { 'type': 'container',
				\ 'title':'[containers]',
				\ 'select':0,
				\ 'highlight_idx': 4,
				\ 'content': s:get(0, l:top),
				\ 'view_content': s:table.stringify(),
				\ 'maxheight': l:maxheight,
				\ 'top': l:top,
				\ 'offset': 0}

	call window#util#create_popup_window(l:ctx)
endfunction

function! docker#container#start_monitor(id) abort
	call docker#monitor#start_monitoring(a:id)
endfunction

function! docker#container#stop_monitor() abort
	call docker#monitor#stop_monitoring()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
