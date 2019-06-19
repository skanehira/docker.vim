let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:HTTP = s:V.import('Web.HTTP')
let s:TABLE = s:V.import('Text.Table')

function! s:_parse_image(image) abort
    let l:repo_tags = split(a:image.RepoTags[0], ':')
    let l:new_image = {}
    let l:new_image.Repo = l:repo_tags[0]
    let l:new_image.Tag = l:repo_tags[1]
    let l:new_image.Id = util#_parse_id(a:image.Id)
    let l:new_image.Created = util#_parse_unix_date(a:image.Created)
    let l:new_image.Size = util#_parse_size(a:image.Size)

    return l:new_image
endfunction

function! image#get() abort
    let response = s:HTTP.request("http://localhost/images/json", {
                \ 'unixSocket': '/var/run/docker.sock'
                \ })

    let images = json_decode(response.content)

    let s:table = s:TABLE.new({
                \ 'columns': [{},{},{},{},{}],
                \ 'header' : ['ID', 'Repository', 'Tag', 'Created', 'Size'],
                \ })

    for image in images
        if image.RepoTags is v:null
            continue
        endif

        let l:image = s:_parse_image(image)
        call s:table.add_row([l:image.Id, l:image.Repo, l:image.Tag, l:image.Created, l:image.Size])
    endfor

    if has("patch-8.1.1561")
        call util#_popup_window(s:table.stringify())
    else
        call util#_create_window(s:table.stringify())
    endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
