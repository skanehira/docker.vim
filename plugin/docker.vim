let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let g:disable_popup_window = 0

command! Images call image#get()
command! Containers call container#get()
command! -nargs=1 Monitor call container#start_monitor(<f-args>)
command! StopMonitor call container#stop_monitor()

let &cpo = s:save_cpo
unlet s:save_cpo
