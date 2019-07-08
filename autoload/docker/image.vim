let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')
let s:table = {}

" get images from docker
function! s:get(offset, top) abort
	let s:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{}],
				\ 'header' : ['ID', 'REPOSITORY', 'TAG', 'CREATED', 'SIZE'],
				\ })

	let l:images = []
	for row in docker#util#http_get("http://localhost/images/json",{})
		if row.RepoTags is v:null
			continue
		endif

		call add(l:images, row)
	endfor

	if len(l:images) ==# 0
		call docker#util#echo_err("no images")
		return []
	endif

	for row in l:images[a:offset: a:offset + a:top - 1]
		let l:image = docker#util#parse_image(row)
		call s:table.add_row([
					\ l:image.Id,
					\ l:image.Repo,
					\ l:image.Tag,
					\ l:image.Created,
					\ l:image.Size])

	endfor

	return l:images
endfunction

" get and popup images
function! docker#image#get() abort
	" highlight_idx is highlight idx
	" select is selected entry
	let l:maxheight = 15
	let l:top = l:maxheight - 4
	let l:ctx = { 'type': 'image',
				\ 'title':'[imgaes]',
				\ 'select':0,
				\ 'highlight_idx': 4,
				\ 'content': s:get(0, l:top),
				\ 'view_content': s:table.stringify(),
				\ 'maxheight': l:maxheight,
				\ 'top': l:top,
				\ 'offset': 0}

	call window#util#create_popup_window(l:ctx)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
