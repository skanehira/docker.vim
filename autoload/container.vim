let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')
let s:table = {}

function! s:parse_id(id) abort
    return a:id[0:11]
endfunction

function! s:_parse_ports(ports) abort
    let _port = ""
    for port in a:ports
        if !has_key(port, 'PublicPort')
            let _port .= printf("%d/%s ", port.PrivatePort, port.Type)
        else
            let _port .= printf("%s:%d->%d/%s ", port.IP, port.PrivatePort, port.PublicPort, port.Type)
        endif
    endfor
    return _port
endfunction

function! s:_parse_container(container) abort
    let _new = {}
    let _new.Id = s:parse_id(a:container.Id)
    let _new.Name = a:container.Names[0][1:]
    let _new.Image = a:container.Image
    let _new.Status = a:container.Status
    let _new.Created = util#parse_unix_date(a:container.Created)
    let _new.Ports = s:_parse_ports(a:container.Ports)
    let _new.Command = a:container.Command
    return _new
endfunction

function! s:get()
    let s:table = s:TABLE.new({
                \ 'columns': [{},{},{},{},{},{}],
                \ 'header' : ['ID', 'NAME', 'IMAGE', 'STATUS', 'CREATED', 'PORTS'],
                \ })

    let l:containers = []
    for row in util#http_get("http://localhost/containers/json",{'all': 1})
        let l:container = s:_parse_container(row)
        call s:table.add_row([
                    \ l:container.Id,
                    \ l:container.Name,
                    \ l:container.Image,
                    \ l:container.Status,
                    \ l:container.Created,
                    \ l:container.Ports
                    \ ])
        call add(l:containers, row)
    endfor

    if len(l:containers) ==# 0
        call util#echo_err("no containers")
    endif

    return l:containers
endfunction

" get and popup images
function! container#get()
    let l:containers = s:get()
    let l:view_containers = s:table.stringify()
    call util#create_popup_window(l:view_containers, l:containers)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
