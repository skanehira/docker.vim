" docker
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

" wrap docker cli
function! docker#docker#execute(...) abort
	if !docker#util#have_docker_cli()
		return
	endif

	if !docker#util#have_terminal()
		return
	endif

	exe printf('%s term docker %s', g:docker_terminal_open, join(a:000, ' '))
	nnoremap <silent> <buffer> q :close<CR>
endfunction

function! docker#docker#event() abort
	if !docker#util#have_docker_cli()
		return
	endif

	if !docker#util#have_terminal()
		return
	endif

	exe printf('%s term ++close docker events', g:docker_terminal_open)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
