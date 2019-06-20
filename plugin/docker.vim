let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

command! Images call image#get()
command! Containers call container#get()

let &cpo = s:save_cpo
unlet s:save_cpo
