" network
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')

function! s:network_get(search_word, offset, top) abort
	let l:table = s:TABLE.new({
				\ 'columns': [{},{},{},{}],
				\ 'header' : ['ID', 'NAME', 'DRIVER', 'SCOPE'],
				\ })

	let l:networks = filter(docker#api#network#get(), 'v:val.Name =~ a:search_word[1:]')

	for network in l:networks[a:offset: a:offset + a:top -1]
		let net = docker#util#parse_network(network)
		call l:table.add_row([
					\ net.Id,
					\ net.Name,
					\ net.Driver,
					\ net.Scope,
					\ ])
	endfor

	return {'content': l:networks,
				\ 'view_content': l:table.stringify(),
				\ }
endfunction

function! docker#network#get() abort
	let l:maxheight = 15
	let l:top = l:maxheight - 4
	let l:contents = s:network_get('', 0, l:top)

	if len(l:contents.content) ==# 0
		call docker#util#echo_err('docker.vim: there are no networks')
		return
	endif

	let l:ctx = { 'type': 'network',
				\ 'title':'[networks]',
				\ 'select':0,
				\ 'highlight_idx': 4,
				\ 'content': l:contents.content,
				\ 'view_content': l:contents.view_content,
				\ 'maxheight': l:maxheight,
				\ 'top': l:top,
				\ 'offset': 0,
				\ 'disable_filter': 0,
				\ 'refresh_timer': 0,
				\ 'search_word': '',
				\ 'search_mode': 0
				\ }

	call window#util#create_popup_window(l:ctx)

	" update every 5 second
	let ctx.refresh_timer = timer_start(5000,
				\ function('s:update_contents_timer', [ctx]),
				\ {'repeat': -1}
				\ )
endfunction

function! s:update_contents_timer(ctx, timer) abort
	call docker#network#update_contents(a:ctx)
endfunction

function! docker#network#update_contents(ctx) abort
	let l:contents = s:network_get(a:ctx.search_word, a:ctx.offset, a:ctx.top)
	let a:ctx.content = l:contents.content
	let a:ctx.view_content = l:contents.view_content
	call window#util#update_poup_window(a:ctx)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
