let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')

" get images from docker engine
" return
" {
" 'content': {images},
" 'view_content': {table}'
" }
function! s:docker_image_get(offset, top) abort
	let l:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{}],
				\ 'header' : ['ID', 'REPOSITORY', 'TAG', 'CREATED', 'SIZE'],
				\ })

	let l:images = docker#api#get_images()

	for row in l:images[a:offset: a:offset + a:top - 1]
		let l:image = docker#util#parse_image(row)
		call l:table.add_row([
					\ l:image.Id,
					\ l:image.Repo,
					\ l:image.Tag,
					\ l:image.Created,
					\ l:image.Size])

	endfor

	return {'content': l:images,
				\ 'view_content': l:table.stringify(),
				\ }
endfunction

" get and popup images
function! docker#image#get() abort
	let l:maxheight = 15
	let l:top = l:maxheight - 4
	let l:contents = s:docker_image_get(0, l:top)

	let l:ctx = { 'type': 'image',
				\ 'title':'[imgaes]',
				\ 'select':0,
				\ 'highlight_idx': 4,
				\ 'content': l:contents.content,
				\ 'view_content': l:contents.view_content,
				\ 'maxheight': l:maxheight,
				\ 'top': l:top,
				\ 'offset': 0}

	call window#util#create_popup_window(l:ctx)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
