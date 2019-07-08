let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:docker_monitor_window = 0
let s:docker_monitor_timer_id = 0
let s:docker_stats_response = []
let s:docker_move_filter_disable = 0

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
" 0   ------------------------
"       CPU(30%)     MEM(40%)
function s:make_graph(cpu, mem) abort
	let graph = []
	call add(graph, '    ------------------------')
	for line_num in [100,90,80,70,60,50,40,30,20,10]
		" 偶数行はパーセンテージの値を表示する
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

	call add(graph, printf('%3d ------------------------','0'))
	call add(graph, printf('      CPU(%d%%)    MEM(%d%%)', a:cpu, a:mem))
	return graph
endfunction

function! s:update_graph(cpu, mem) abort
	call win_execute(s:docker_monitor_window, '%d_')
	call setbufline(winbufnr(s:docker_monitor_window), 1, s:make_graph(a:cpu, a:mem))
endfunction

function! s:stats_out_cb(ch, result) abort
	let s:docker_stats_response = []
	call add(s:docker_stats_response, json_decode(a:result))
endfunction

function! s:stats_exit_cb(job, status) abort
	if empty(s:docker_stats_response)
		call util#echo_err('response is empty')
		call monitor#stop_monitoring()
		return
	endif

	let response = s:docker_stats_response[0]
	if has_key(response, 'message')
		call monitor#stop_monitoring()
		return
	endif
	call s:update_graph(s:calculate_cpu(response), s:calculate_mem(response))
endfunction

function! s:update_stats(id, timer) abort
	let cmd = ['curl', '-s', '--unix-socket', '/var/run/docker.sock', 'http://localhost/containers/' .. a:id ..'/stats?stream=false']

	call job_start(cmd, {
				\'callback': function('s:stats_out_cb'),
				\'exit_cb': function('s:stats_exit_cb'),
				\})
endfunction

function! s:calculate_cpu(response) abort
	let cpu_percent = 0
	let cpu_stats = a:response.cpu_stats
	let precpu_stats = a:response.precpu_stats
	let cpu_delta = cpu_stats.cpu_usage.total_usage - precpu_stats.cpu_usage.total_usage
	" if container not runnnig
	if cpu_delta ==# 0
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

" move popup window
" left  = 0
" down  = 1
" up    = 2
" right = 3
function! s:move_monitor_window(id, way) abort
	let opt = popup_getoptions(a:id)
	if type(opt) !=# type({})
		return 0
	endif

	if a:way ==# 0
		let opt.col -= 1
	elseif a:way ==# 1
		let opt.line += 1
	elseif a:way ==# 2
		let opt.line -= 1
	elseif a:way ==# 3
		let opt.col += 1
	endif
	call popup_move(a:id, opt)

	return 1
endfunction

function! s:move_monitor_window_filter(id, key) abort
	if s:docker_move_filter_disable ==# 1
		return 0
	endif

	if a:key ==# 'h'
		return s:move_monitor_window(a:id, 0)
	elseif a:key ==# 'j'
		return s:move_monitor_window(a:id, 1)
	elseif a:key ==# 'k'
		return s:move_monitor_window(a:id, 2)
	elseif a:key ==# 'l'
		return s:move_monitor_window(a:id, 3)
	elseif a:key ==# "\n" || a:key ==# "\r"
		let s:docker_move_filter_disable = 1
		return 0
	endif
	return 1
endfunction

function! docker#monitor#start_monitoring(id) abort
	" not support windows
	if has('win32') || has ('win64')
		" TODO support windows
		echoerr 'not support windows'
		return
	endif

	if s:docker_monitor_window !=# 0
		call popup_close(s:docker_monitor_window)
	endif

	let s:docker_move_filter_disable = 0
	let s:docker_monitor_window = popup_create(s:make_graph(0,0),{
				\ 'filter': function('s:move_monitor_window_filter'),
				\ })

	let s:docker_monitor_timer_id = timer_start(2000, function('s:update_stats', [a:id]), {'repeat': -1})
endfunction

function! docker#monitor#stop_monitoring() abort
	silent call timer_stop(s:docker_monitor_timer_id)
	call popup_close(s:docker_monitor_window)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
