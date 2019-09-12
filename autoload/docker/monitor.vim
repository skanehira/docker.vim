" docker.vim
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:monitor_window = 0
let s:monitor_timer_id = 0
let s:keys = {
			\ 'left'  : 104,
			\ 'down'  : 106,
			\ 'up'    : 107,
			\ 'right' : 108,
			\ 'enter' : 13,
			\ }

" id: 4ee503fb4646
"     +----------------------+
" 100 -                      |
"     |                      |
" 80  -                      |
"     |                      |
" 60  -                      |
"     |                      |
" 40  -                      |
"     |              ■■■■■■  |
" 20  -  ■■■■■■      ■■■■■■  |
"     |  ■■■■■■      ■■■■■■  |
" 0   +----------------------+
"       CPU(30%)     MEM(40%)
function s:make_graph(id, cpu, mem) abort
	let graph = []
	call add(graph, 'id: ' .. a:id)
	call add(graph, '    +----------------------+')
	for line_num in [100,90,80,70,60,50,40,30,20,10]
		let line = ''
		if line_num % 20 ==# 0
			let line = printf('%3d -',line_num)
		else
			let line = '    |'
		endif

		if line_num <= a:cpu
			let line = line .. '  ■■■■■■'
		else
			let line = line .. '        '
		endif
		if line_num <= a:mem
			let line =line .. '      ■■■■■■  |'
		else
			let line =line .. '              |'
		endif

		call add(graph, line)
	endfor

	call add(graph, printf('%3d +----------------------+','0'))
	call add(graph, printf('      CPU(%d%%)    MEM(%d%%)', a:cpu, a:mem))
	return graph
endfunction

function! s:update_graph(id, cpu, mem) abort
	call popup_settext(s:monitor_window, s:make_graph(a:id, a:cpu, a:mem))
endfunction

function! s:stats_out_cb(id, ch, result) abort
	let res = json_decode(a:result)
	if empty(res)
		call docker#monitor#stop()
		return
	endif

	if has_key(res, 'message')
		call docker#util#echo_err('docker.vim: ' .. res.message)
		call docker#monitor#stop()
		return
	endif
	call s:update_graph(a:id, s:calculate_cpu(res), s:calculate_mem(res))
endfunction

function! s:update_stats(id, timer) abort
	let cmd = ['curl', '-s', '--unix-socket', '/var/run/docker.sock', 'http://localhost/containers/' .. trim(a:id) ..'/stats?stream=false']

	call job_start(cmd, {
				\'callback': function('s:stats_out_cb', [docker#util#parse_container_id(a:id)]),
				\})
endfunction

function! s:calculate_cpu(response) abort
	try
		let cpu_percent = 0
		let cpu_stats = a:response.cpu_stats
		let precpu_stats = a:response.precpu_stats
		let cpu_delta = cpu_stats.cpu_usage.total_usage - precpu_stats.cpu_usage.total_usage
		" if container not runnnig
		if cpu_delta ==# 0
			return 0
		endif

		" issue #1
		" an error occurs if the container stop while monitoring cpu/mem
		" if stop container while monitoring, cpu_stats don't have system_cpu_usage value
		if !has_key(cpu_stats, 'system_cpu_usage')
			return 0
		endif
		let system_delta = cpu_stats.system_cpu_usage - precpu_stats.system_cpu_usage
		let online_cpus  = cpu_stats.online_cpus
		if online_cpus == 0
			let online_cpus = len(cpu_stats.cpu_usage.percpu_usage)
		endif

		if system_delta > 0 && cpu_delta > 0
			let cpu_percent = (cpu_delta * 1.0 / system_delta) * online_cpus * 100
		endif
	catch
		call docker#util#echo_err('docker.vim: ' .. v:exception)
	endtry

	return float2nr(cpu_percent)
endfunction

function! s:calculate_mem(response) abort
	let mem_stats = a:response.memory_stats
	if !has_key(mem_stats, 'limit')
		return 0
	endif
	if mem_stats.limit ==# 0
		return 0
	endif
	let usage = (mem_stats.usage - mem_stats.stats.cache)
	return  float2nr(usage * 1.0 / mem_stats.limit * 100)
endfunction

function! docker#monitor#move() abort
	if s:monitor_window ==# 0
		call docker#util#echo_err('docker.vim: no monitor window')
		return
	endif
	echo '[move monitor window]... "h": left, "j": down, "k": up, "l": right, "Enter": finish'

	while 1
		let opt = popup_getpos(s:monitor_window)
		if type(opt) !=# type({}) || empty(opt)
			call docker#util#echo_err('docker.vim: cannot get monitor window position')
			break
		endif

		let c = getchar()
		if c ==# s:keys.enter
			redraw
			echo ''
			break
		endif

		if c ==# s:keys.left
			let opt.col -= 2
		elseif c ==# s:keys.down
			let opt.line += 2
		elseif c ==# s:keys.up
			let opt.line -= 2
		elseif c ==# s:keys.right
			let opt.col += 2
		endif
		call popup_move(s:monitor_window, opt)
		redraw
	endwhile
endfunction

function! docker#monitor#start(id) abort
	" not support windows
	if has('win32') || has ('win64')
		" TODO support windows
		call docker#util#echo_err('docker.vim: doesn''t support windows')
		return
	endif

	call docker#monitor#stop()

	let s:monitor_window = popup_create(s:make_graph(docker#util#parse_container_id(a:id), 0, 0),{
				\ 'callback': function('s:stop_monitor_timer'),
				\ 'line': &lines/2-6,
				\ 'col': &columns/2-12,
				\ })

	let s:monitor_timer_id = timer_start(2000, function('s:update_stats', [a:id]), {'repeat': -1})
endfunction

function! s:stop_monitor_timer(id, result) abort
	silent call timer_stop(s:monitor_timer_id)
	let s:monitor_window = 0
	let s:monitor_timer_id = 0
endfunction

function! docker#monitor#stop() abort
	silent call timer_stop(s:monitor_timer_id)
	call popup_close(s:monitor_window)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
