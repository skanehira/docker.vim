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

	let l:images = docker#api#image#get()

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

" get images and display on popup window
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

" update contents
function! s:docker_update_contents(ctx) abort
	let l:contents = s:docker_image_get(a:ctx.offset, a:ctx.top)
	let a:ctx.content = l:contents.content
	let a:ctx.view_content = l:contents.view_content
endfunction

" delete image
function! s:docker_delete_image(ctx, id, key) abort
	if a:key ==# -1 || a:key ==# 0
		return
	endif
	call docker#api#image#delete(a:ctx.content[a:ctx.select].Id)
	call s:docker_update_contents(a:ctx)
endfunction

" this is popup window filter function
function! docker#image#functions(ctx, key) abort
	let l:entry = a:ctx.content[a:ctx.select]
	if a:key ==# 'd'
		call popup_create("Do you delete the image? y/n",{
					\ 'border': [],
					\ 'filter': 'popup_filter_yesno',
					\ 'callback': function('s:docker_delete_image', [a:ctx]),
					\ 'zindex': 51,
					\ })
	elseif a:key ==# 'R'
		call s:docker_update_contents(a:ctx)
	endif
endfunction

" pull image
function! docker#image#pull() abort
	let image = input("image:")
	if image ==# ''
		call docker#util#echo_err('please input command')
		return
	endif
	call docker#api#image#pull(image)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
