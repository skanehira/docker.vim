" docker.vim
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')

function! s:filter(id, key) abort
	if a:key ==# 'q'
		call popup_close(a:id)
	endif
	return 1
endfunction

" get docker version info and display popup window
function! docker#version#info() abort
	let l:table = s:TABLE.new({
				\ 'columns': [{},{}]
				\ })

	for row in docker#api#version#info()
		call l:table.add_row([
					\ row.item,
					\ row.value
					\ ])
	endfor

	call popup_create(l:table.stringify(), {
				\ 'filter': function('s:filter'),
				\ 'title': 'version info',
				\ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
