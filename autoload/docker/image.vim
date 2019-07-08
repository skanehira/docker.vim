let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')
let s:table = {}

" get images from docker
function! s:get() abort
	let l:images = []
	let s:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{}],
				\ 'header' : ['ID', 'REPOSITORY', 'TAG', 'CREATED', 'SIZE'],
				\ })

	for row in docker#util#http_get("http://localhost/images/json",{})
		if row.RepoTags is v:null
			continue
		endif

		let l:image = docker#util#parse_image(row)
		call s:table.add_row([
					\ l:image.Id,
					\ l:image.Repo,
					\ l:image.Tag,
					\ l:image.Created,
					\ l:image.Size])
		call add(l:images, row)
	endfor
	if len(l:images) ==# 0
		call docker#util#echo_err("no images")
	endif

	return l:images
endfunction

" get and popup images
function! docker#image#get() abort
	let l:images = s:get()
	let l:view_images = s:table.stringify()
	call window#util#create_popup_window("images", "image", l:view_images, images)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
