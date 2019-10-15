" network
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:Base64 = s:V.import('Data.Base64')

function! docker#api#network#get() abort
	let l:response = docker#api#http#get('http://localhost/networks', {})

	if l:response.status !=# 200
		call window#util#notification_failed(json_decode(l:response.content).message)
		return []
	endif

	let networks = sort(json_decode(l:response.content))

	for net in networks
		let detail = docker#api#network#inspect(net.Id)
		let containers = []
		for con in values(detail.Containers)
			call add(containers, con.Name)
		endfor

		let net['Containers'] = containers
	endfor

	return networks
endfunction

function! docker#api#network#inspect(id) abort
	let l:response = docker#api#http#get('http://localhost/networks/' .. a:id, {})

	if l:response.status !=# 200
		call window#util#notification_failed(json_decode(l:response.content).message)
		return []
	endif

	return json_decode(l:response.content)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
