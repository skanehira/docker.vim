" docker
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

" wrap docker command
function! docker#docker#execute(...) abort
	if !executable('docker')
		call docker#util#echo_err('there are no docker command')
		return
	endif

	if !has('terminal')
		call docker#util#echo_err('terminal is not support')
		return
	endif

	exe printf('%s term docker %s', g:docker_terminal_open, join(a:000, ' '))
	nnoremap <silent> <buffer> q :close<CR>
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
