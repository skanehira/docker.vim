" docker.vim
" Version: 0.2.1
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

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
function! s:image_get(offset, top) abort
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
	let l:contents = s:image_get(0, l:top)

	let l:ctx = { 'type': 'image',
				\ 'title':'[imgaes]',
				\ 'select':0,
				\ 'highlight_idx': 4,
				\ 'content': l:contents.content,
				\ 'view_content': l:contents.view_content,
				\ 'maxheight': l:maxheight,
				\ 'top': l:top,
				\ 'offset': 0,
				\ 'disable_filter': 0}

	call window#util#create_popup_window(l:ctx)
endfunction

" update contents
function! s:update_contents(ctx) abort
	let l:contents = s:image_get(a:ctx.offset, a:ctx.top)
	let a:ctx.content = l:contents.content
	let a:ctx.view_content = l:contents.view_content
endfunction

" delete image
function! s:delete_image(ctx) abort
	let a:ctx.disable_filter = 1
	let result = input('Do you delete the image? y/n:')
	if result ==# 'y' || result ==# 'Y'
		call docker#api#image#delete(a:ctx, function('s:update_contents'))
	else
		let a:ctx.disable_filter = 0
		echo ''
		redraw
	endif
endfunction

" this is popup window filter function
function! docker#image#functions(ctx, key) abort
	let l:entry = a:ctx.content[a:ctx.select]
	if a:key ==# ''
		call s:delete_image(a:ctx)
	elseif a:key ==# 'R'
		call s:update_contents(a:ctx)
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

" search image
function! s:image_search(term, offset, top) abort
	let l:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{}],
				\ 'header' : ['NAME',  'DESCRIPTION', 'STARS', 'OFFICIAL', 'AUTOMATED'],
				\ })

	let l:search_images = docker#api#image#search(a:term)

	let l:images = []
	for row in l:search_images
		let image = {
					\ 'name': row.name,
					\ 'description': row.description[:30],
					\ 'stars': printf("%d", row.star_count),
					\ 'official': row.is_official ? "[OK]" : "",
					\ 'automated': row.is_automated ? "[OK]": ""
					\ }

		call add(l:images, image)

	endfor

	for image in l:images[a:offset: a:offset + a:top - 1]
		call l:table.add_row([
					\ image.name,
					\ image.description,
					\ image.stars,
					\ image.official,
					\ image.automated])
	endfor

	return {'content': l:images,
				\ 'view_content': l:table.stringify(),
				\ }
endfunction

" search image
function! docker#image#search(term) abort
	let l:maxheight = 15
	let l:top = l:maxheight - 4
	let l:contents = s:image_search(a:term, 0, l:top)

	let l:ctx = { 'type': 'search',
				\ 'title':'[search imgaes]',
				\ 'select':0,
				\ 'highlight_idx': 4,
				\ 'content': l:contents.content,
				\ 'view_content': l:contents.view_content,
				\ 'maxheight': l:maxheight,
				\ 'top': l:top,
				\ 'offset': 0,
				\ 'disable_filter': 0}

	call window#util#create_popup_window(l:ctx)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
