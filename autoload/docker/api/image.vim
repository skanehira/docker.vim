" docker.vim
" Version: 0.2.1
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

" get images
function! docker#api#image#get() abort
	let l:response = docker#api#http#get("http://localhost/images/json", {})

	if l:response.status !=# 200
		call docker#util#echo_err(json_decode(l:response.content).message)
		return []
	endif

	let l:images = []
	for content in json_decode(l:response.content)
		" if repo is null not add to list
		if content.RepoTags is v:null
			continue
		endif

		call add(l:images, content)
	endfor
	return l:images
endfunction

" delete image callback
function! s:image_delete_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 200
		call docker#util#echo_err(a:response.content.message)
	endif
	call a:updatefunc(a:ctx)
	let a:ctx.disable_filter = 0
endfunction

" delete image
function! docker#api#image#delete(ctx, updatefunc) abort
	let id = a:ctx.content[a:ctx.select].Id
	echo 'deleting' id
	redraw
	call docker#api#http#async_delete("http://localhost/images/" .. id, 
				\ {}, 
				\ function('s:image_delete_cb', [a:ctx, a:updatefunc]),
				\ )
endfunction

" image pull callback
function! s:image_pull_cb(image, response) abort
	if a:response.status ==# 200
		call window#util#notification_success(printf('pulling %s is successed', a:image))
	else
		call window#util#notification_failed(a:response.content.message)
	endif
endfunction

" pull image
function! docker#api#image#pull(image) abort
	let image_tag = split(a:image, ':')
	if len(image_tag) < 2
		call add(image_tag, 'latest')
	endif

	redraw
	echo ''

	let param = join(image_tag, ":")
	call window#util#notification(printf("%s... %s", "pulling", param), 'normal')

	call docker#api#http#async_post("http://localhost/images/create", 
				\ {'fromImage': param},
				\ {},
				\ function('s:image_pull_cb', [param]),
				\ )
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
