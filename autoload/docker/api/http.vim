" http
" Version: 0.0.1
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:HTTP = s:V.import('Web.HTTP')

" http get
function! docker#api#http#get(url, param) abort
	return s:HTTP.request(a:url, {
				\ 'unixSocket': '/var/run/docker.sock',
				\ 'param': a:param
				\ })
endfunction

" http post
function! docker#api#http#post(url, param, data) abort
	return s:HTTP.request(a:url, {
				\ 'unixSocket': '/var/run/docker.sock',
				\ 'method': 'POST',
				\ 'param': a:param,
				\ 'data' : a:data,
				\ })
endfunction

" http delete
function! docker#api#http#delete(url, param, data) abort
	return s:HTTP.request(a:url, {
				\ 'unixSocket': '/var/run/docker.sock',
				\ 'method': 'DELETE',
				\ 'param': a:param,
				\ 'data' : a:data,
				\ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
