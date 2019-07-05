let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')
let s:table = {}

function! s:parse_id(id) abort
	return a:id[7:19]
endfunction

function! s:_parse_image(image) abort
	let l:repo_tags = split(a:image.RepoTags[0], ':')
	let l:new_image = {}
	let l:new_image.Repo = l:repo_tags[0]
	let l:new_image.Tag = l:repo_tags[1]
	let l:new_image.Id = s:parse_id(a:image.Id)
	let l:new_image.Created = util#parse_unix_date(a:image.Created)
	let l:new_image.Size = util#parse_size(a:image.Size)

	return l:new_image
endfunction

" get images from docker
function! s:get() abort
	let l:images = []
	let s:table = s:TABLE.new({
				\ 'columns': [{},{},{},{},{}],
				\ 'header' : ['ID', 'REPOSITORY', 'TAG', 'CREATED', 'SIZE'],
				\ })

	for row in util#http_get("http://localhost/images/json",{})
		if row.RepoTags is v:null
			continue
		endif

		let l:image = s:_parse_image(row)
		call s:table.add_row([
					\ l:image.Id,
					\ l:image.Repo,
					\ l:image.Tag,
					\ l:image.Created,
					\ l:image.Size])
		call add(l:images, row)
	endfor
	if len(l:images) ==# 0
		call util#echo_err("no images")
	endif

	return l:images
endfunction

" get and popup images
function! image#get()
	let l:images = s:get()
	let l:view_images = s:table.stringify()
	call util#create_popup_window(l:view_images, images)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
