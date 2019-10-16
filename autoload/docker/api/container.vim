" docker.vim
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

" get containers
function! docker#api#container#get() abort
	let l:response = docker#api#http#get('http://localhost/containers/json', {'all': 1})

	if l:response.status !=# 200
		call window#util#notification_failed(json_decode(l:response.content).message)
		return []
	endif

	return json_decode(l:response.content)
endfunction

" container start callback
function! s:container_start_cb(ctx, updatefunc, response) abort
	if a:response.status ==# 304
		call window#util#notification_success('container is already started')
	elseif a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('started ' .. a:ctx.content[a:ctx.select].Names[0][1:])
	endif
	call a:updatefunc(a:ctx)
endfunction

" start container
function! docker#api#container#start(ctx, updatefunc) abort
	let entry = a:ctx.content[a:ctx.select]
	call window#util#notification_normal('starting... ' .. entry.Names[0][1:])
	call docker#api#http#async_post(1, 'http://localhost/containers/' .. entry.Id .. '/start',
				\ {},
				\ {},
				\ {},
				\ function('s:container_start_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" container stop callback
function! s:container_stop_cb(ctx, updatefunc, response) abort
	if a:response.status ==# 304
		call window#util#notification_success(a:ctx.content[a:ctx.select].Names[0][1:] .. ' is already stopped')
	elseif a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('stopped ' .. a:ctx.content[a:ctx.select].Names[0][1:])
	endif
	call a:updatefunc(a:ctx)
endfunction

" stop container
function! docker#api#container#stop(ctx, updatefunc) abort
	let entry = a:ctx.content[a:ctx.select]
	call window#util#notification_normal('stopping... ' .. entry.Names[0][1:])
	call docker#api#http#async_post(1, 'http://localhost/containers/' .. entry.Id .. '/stop',
				\ {},
				\ {},
				\ {},
				\ function('s:container_stop_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" restart container callback
function! s:container_restart_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('restarted ' .. a:ctx.content[a:ctx.select].Names[0][1:])
	endif
	call a:updatefunc(a:ctx)
endfunction

" restart container
function! docker#api#container#restart(ctx, updatefunc) abort
	let entry = a:ctx.content[a:ctx.select]
	call window#util#notification_normal('restaring... ' .. entry.Names[0][1:])
	call docker#api#http#async_post(1, 'http://localhost/containers/' .. entry.Id .. '/restart',
				\ {},
				\ {},
				\ {},
				\ function('s:container_restart_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" delete container callback
function! s:container_delete_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('deleted ' .. a:ctx.content[a:ctx.select].Names[0][1:])
	endif

	if a:ctx.select ==# len(a:ctx.content) - 1
		call feedkeys('k')
	endif

	call a:updatefunc(a:ctx)
endfunction

" delete container
function! docker#api#container#delete(ctx, updatefunc) abort
	let entry = a:ctx.content[a:ctx.select]

	try
		if docker#api#container#is_running(entry.Id)
			call window#util#notification_failed(entry.Names[0][1:] .. ' is running')
			return
		endif
	catch /.*/
		call window#util#notification_failed(v:exception)
		return
	endtry

	call window#util#notification_normal('deleting... ' .. entry.Names[0][1:])
	call docker#api#http#async_delete(1, 'http://localhost/containers/' .. entry.Id,
				\ {},
				\ function('s:container_delete_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" attach to a container using docker cli
function! docker#api#container#attach(name, cmd) abort
	echo ''
	if !docker#util#have_terminal()
		return
	endif

	if !docker#util#have_docker_cli()
		return
	endif

	exe printf('%s term ++close docker exec -it %s %s', g:docker_terminal_open, a:name, a:cmd)
endfunction

function! s:container_kill_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('killed ' .. a:ctx.content[a:ctx.select].Names[0][1:])
	endif
	call a:updatefunc(a:ctx)
endfunction

" kill container
function! docker#api#container#kill(ctx, updatefunc) abort
	let entry = a:ctx.content[a:ctx.select]
	call window#util#notification_normal('killing... ' .. entry.Names[0][1:])
	call docker#api#http#async_post(1, "http://localhost/containers/" .. entry.Id .. "/kill",
				\ {},
				\ {},
				\ {},
				\ function('s:container_kill_cb', [a:ctx, a:updatefunc]),
				\ )
endfunction

" rename container callback
function! s:container_rename_cb(ctx, updatefunc, response) abort
	if a:response.status !=# 204
		call window#util#notification_failed(a:response.content.message)
	else
		call window#util#notification_success('renamed ' .. a:ctx.name)
	endif
	call a:updatefunc(a:ctx)
endfunction

" rename container
function! docker#api#container#rename(ctx, updatefunc) abort
	echo ''
	call window#util#notification_normal(printf('renaming to %s...', a:ctx.name))
	call docker#api#http#async_post(1, 'http://localhost/containers/' .. a:ctx.content[a:ctx.select].Id .. '/rename',
				\ {'name': a:ctx.name},
				\ {},
				\ {},
				\ function('s:container_rename_cb', [a:ctx, a:updatefunc])
				\ )
endfunction

" tail container logs
" if container is not running, terminal does not close automatically
function! docker#api#container#logs(entry) abort
	if !docker#util#have_terminal()
		call window#util#notification_failed('terminal is not support')
		return
	endif

	if !docker#util#have_docker_cli()
		return
	endif

	try
		let name = a:entry.Names[0][1:]
		if docker#api#container#is_running(a:entry.Id)
			exe printf('%s term ++close docker logs -f %s', g:docker_terminal_open, name)
		else
			exe printf('%s term docker logs -f %s', g:docker_terminal_open, name)
			nnoremap <silent> <buffer> q :close<CR>
		endif
	catch /.*/
		call window#util#notification_failed(v:exception)
	endtry
endfunction

" check the container state
" if the container is running then will return true
function! docker#api#container#is_running(id) abort
	let l:response = docker#api#http#get('http://localhost/containers/' .. a:id .. '/json', {})
	if l:response.status !=# 200
		throw json_decode(l:response.content).message
	endif
	return json_decode(l:response.content).State.Running
endfunction

" run container
function! docker#api#container#run(ctx) abort
	if !docker#util#have_terminal()
		return
	endif

	if !docker#util#have_docker_cli()
		return
	endif

	let name = a:ctx.content[a:ctx.select].RepoTags[0]

	let a:ctx.disable_filter = 1
	let args = input('args:')
	let cmd = input('cmd:')
	echo ''
	let a:ctx.disable_filter = 0

	call popup_close(a:ctx.id)

	let excmd = g:docker_terminal_open .. ' term docker run'
	if !empty(args)
		let excmd = excmd .. ' ' .. args
	endif

	let excmd = excmd .. ' ' .. name

	if !empty(cmd)
		let excmd = excmd .. ' ' .. cmd
	endif

	exe excmd
	nnoremap <silent> <buffer> q :close<CR>
endfunction

function! s:docker_cp_exit_cb(msg, ch, status) abort
	if a:status !=# 0
		return
	endif
	call window#util#notification_success(a:msg .. ' is successed')
endfunction

function! s:docker_cp_err_cb(ch, msg) abort
	call docker#util#echo_err('copy is failed: ' .. a:msg)
endfunction

function! docker#api#container#cp(ctx) abort
	if !docker#util#have_terminal()
		return
	endif

	let a:ctx.disable_filter = 1

	" from is mean copy resource from container
	" to is mean copy resource to container
	let from_or_to = input('from or to container(from/to):')
	if from_or_to ==# '' || (from_or_to !=# 'to' && from_or_to !=# 'from')
		call docker#util#echo_err('docker.vim: please input "from" or "to"')
		let a:ctx.disable_filter = 0
		return
	endif

	let con_src = input('container resource:')
	if con_src ==# ''
		call docker#util#echo_err('docker.vim: please input container resource')
		let a:ctx.disable_filter = 0
		return
	endif

	let loc_src = input('local resource:')
	if loc_src ==# ''
		call docker#util#echo_err('docker.vim: please input local resource')
		let a:ctx.disable_filter = 0
		return
	endif

	let a:ctx.disable_filter = 0

	let id = a:ctx.content[a:ctx.select].Id
	let cmd = ['docker', 'cp']
	let msg = ''

	if from_or_to ==# 'from'
		let cmd = cmd + [id .. ':' .. con_src, loc_src]
		let msg = printf('copy %s to %s', con_src, loc_src)
	else
		let cmd = cmd + [loc_src, id .. ':' .. con_src]
		let msg = printf('copy %s to %s', loc_src, con_src)
	endif

	call window#util#notification_normal(msg)
	call job_start(cmd, {
				\ 'exit_cb': function('s:docker_cp_exit_cb', [msg]),
				\ 'err_cb': function('s:docker_cp_err_cb'),
				\ })
endfunction

function! s:docker_commit_exit_cb(repotag, ch, status) abort
	if a:status != 0
		return
	endif

	call window#util#notification_success('commited to ' .. a:repotag)
endfunction

function! s:docker_commit_err_cb(ch, msg) abort
	call window#util#notification_failed('commit is failed ' .. a:msg)
endfunction

function! docker#api#container#commit(ctx) abort
	if !docker#util#have_terminal()
		return
	endif

	let name = a:ctx.content[a:ctx.select].Names[0][1:]
	let cmd = ['docker', 'commit', name, a:ctx.repotag]

	call window#util#notification_normal('committing to ' .. a:ctx.repotag .. '...')

	call job_start(cmd, {
				\ 'exit_cb': function('s:docker_commit_exit_cb', [a:ctx.repotag]),
				\ 'err_cb': function('s:docker_commit_err_cb'),
				\ })
endfunction

function! docker#api#container#inspect_term(ctx) abort
	let container_name = a:ctx.content[a:ctx.select].Names[0][1:]
	exe printf('%s term docker container inspect %s', g:docker_terminal_open, container_name)
	nnoremap <silent> <buffer> q :close<CR>
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
