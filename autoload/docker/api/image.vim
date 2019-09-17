" docker.vim
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:Base64 = s:V.import('Data.Base64')
let s:build_result_buffer_name = '[DOCKER BUILD]'

" get images
function! docker#api#image#get() abort
	let l:response = docker#api#http#get('http://localhost/images/json', {})

	if l:response.status !=# 200
		call window#util#notification_failed(json_decode(l:response.content).message)
		return []
	endif

	let l:images = []
	for content in json_decode(l:response.content)
		" if repo is null not add to list
		if content.RepoTags is v:null
			continue
		endif

		if len(content.RepoTags) > 1
			for repo_tag in content.RepoTags
				let con = copy(content)
				let con.RepoTags = [repo_tag]
				call add(l:images, con)
			endfor
		else
			call add(l:images, content)
		endif

	endfor
	return l:images
endfunction

" delete image callback
function! s:image_delete_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 200
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('deleted ' .. a:ctx.content[a:ctx.select].RepoTags[0])
	endif

	if a:ctx.select ==# len(a:ctx.content) - 1
		call feedkeys('k')
	endif

	call a:updatefunc(a:ctx)
endfunction

" delete image
function! docker#api#image#delete(ctx, updatefunc) abort
	let entry = a:ctx.content[a:ctx.select]
	call window#util#notification_normal('deleting... ' .. entry.RepoTags[0])
	call docker#api#http#async_delete(1, 'http://localhost/images/' .. entry.RepoTags[0],
				\ {},
				\ function('s:image_delete_cb', [a:ctx, a:updatefunc]),
				\ )
endfunction

" image pull callback
function! s:image_pull_cb(image, response) abort
	if a:response.status !=# 200
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('pulled ' .. a:image)
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
	call window#util#notification_normal('pulling... ' .. param)

	call docker#api#http#async_post(1, 'http://localhost/images/create',
				\ {'fromImage': param},
				\ {},
				\ {},
				\ function('s:image_pull_cb', [param]),
				\ )
endfunction

" push image callback
function! s:image_push_cb(repoTag, response) abort
	if a:response.status !=# 200
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('pushed ' .. a:repoTag)
	endif
endfunction

" push image
function! docker#api#image#push(ctx) abort
	let entry = a:ctx.content[a:ctx.select]
	let [name, tag] = split(entry.RepoTags[0], ':')
	let repoTag = entry.RepoTags[0]

	" get X-Registry-Auth config
	let auth_config = get(g:, 'docker_registry_auth', {})

	if type(auth_config) != v:t_dict
		call docker#util#echo_err('docker.vim: g:docker_registry_auth is not dictionary')
		return
	endif

	if empty(auth_config)
		call docker#util#echo_err('docker.vim: g:docker_registry_auth is empty, please set your auth info')
		return
	endif

	let auth_config_encoded = s:Base64.encode(json_encode(auth_config))

	call window#util#notification_normal('pushing... ' .. repoTag)
	call docker#api#http#async_post(1, 'http://localhost/images/' .. name .. '/push',
				\ {'tag': tag, },
				\ {'X-Registry-Auth': auth_config_encoded},
				\ {},
				\ function('s:image_push_cb', [repoTag]),
				\ )
endfunction

" tag an image callback
function! s:image_tag_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 201
		call window#util#notification_failed(a:response.content.message)
	else
		let repoTag = a:ctx.newRepo .. ':' .. a:ctx.newTag
		call window#util#notification_success('tagged ' .. repoTag)
	endif

	call a:updatefunc(a:ctx)
endfunction

" tag an image
function! docker#api#image#tag(ctx, updatefunc) abort
	let entry = a:ctx.content[a:ctx.select]

	call docker#api#http#async_post(1, 'http://localhost/images/' .. entry.Id .. '/tag',
				\ {'repo': a:ctx.newRepo, 'tag': a:ctx.newTag},
				\ {},
				\ {},
				\ function('s:image_tag_cb', [a:ctx, a:updatefunc]),
				\ )
endfunction

" search images
function! docker#api#image#search(term) abort
	redraw
	echo 'saerching' a:term .. '...'
	let l:response = docker#api#http#get('http://localhost/images/search', {'term': a:term})

	if l:response.status !=# 200
		call window#util#notification_failed(json_decode(l:response.content).message)
		return []
	endif

	echo ''
	return json_decode(l:response.content)
endfunction

function! s:docker_build_buffer_number() abort
	return bufnr('\' .. s:build_result_buffer_name[:-2] .. '\]')
endfunction

function! docker#api#image#build(first, last, ...) abort
	if !docker#util#have_terminal()
		return
	endif

	if !docker#util#have_docker_cli()
		return
	endif

	let build_result_winid = win_findbuf(s:docker_build_buffer_number())
	let current_winid = win_getid(winnr())
	let current_buf = bufnr("%")

	" if have no result window
	if empty(build_result_winid)
		exe "new | e " .. s:build_result_buffer_name
		set buftype=nofile
		nnoremap <buffer> <silent> q :bw<CR>
	else
		" if result window already opened, delete contents
		call win_gotoid(build_result_winid[0])
		exe "%d_"
	endif
	call win_gotoid(current_winid)

	let cmd = ['docker', 'build'] + a:000
	let opt = {
				\ 'out_io': 'buffer',
				\ 'out_name': s:build_result_buffer_name,
				\ 'out_msg': 0,
				\ 'err_io': 'buffer',
				\ 'err_name': s:build_result_buffer_name,
				\ 'err_msg': 0,
				\ }

	" is last arg is '-', stdin from buffer
	if a:000[-1] ==# '-'
		let opt['in_io']  = 'buffer'
		let opt['in_buf'] = current_buf
		let opt['in_top'] = a:first
		let opt['in_bot'] = a:last
	endif

	call job_start(cmd, opt)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
