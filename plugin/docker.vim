let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let g:disable_popup_window = 0

command! Images call docker#image#get()
command! Containers call docker#container#get()
command! -nargs=1 Monitor call docker#container#start_monitor(<f-args>)
command! StopMonitor call docker#container#stop_monitor()

let &cpo = s:save_cpo
unlet s:save_cpo
