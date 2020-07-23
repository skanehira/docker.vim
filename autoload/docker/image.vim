" docker.vim
" Author : skanehira <sho19921005@gmail.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

let s:V = vital#docker#new()
let s:TABLE = s:V.import('Text.Table')

" get images from docker engine
" return
" {
" 'content': {images},
" 'view_content': {table}'
" }
function! s:image_get(search_word, offset, top) abort
  let l:table = s:TABLE.new({
        \ 'columns': [{},{},{},{},{}],
        \ 'header' : ['ID', 'REPOSITORY', 'TAG', 'CREATED', 'SIZE'],
        \ })

  let l:images = filter(docker#api#image#get(), 'split(v:val.RepoTags[0], ":")[0] =~ a:search_word[1:]')

  for row in l:images[a:offset: a:offset + a:top - 1]
    let l:image = docker#util#parse_image(row)
    call l:table.add_row([
          \ l:image.Id,
          \ l:image.Repo,
          \ l:image.Tag,
          \ l:image.Created,
          \ l:image.Size])

  endfor

  return {'content': l:images,
        \ 'view_content': l:table.stringify(),
        \ }
endfunction

" get images and display on popup window
function! docker#image#get() abort
  let l:maxheight = 15
  let l:top = l:maxheight - 4
  let l:contents = s:image_get('', 0, l:top)

  if len(l:contents.content) ==# 0
    call docker#util#echo_err('docker.vim: there are no images')
    return
  endif

  let l:ctx = { 'type': 'image',
        \ 'title':'[imgaes]',
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

" update every specified time
function! s:update_contents_timer(ctx, timer) abort
  call docker#image#update_contents(a:ctx)
endfunction

" update contents
function! docker#image#update_contents(ctx) abort
  let l:contents = s:image_get(a:ctx.search_word, a:ctx.offset, a:ctx.top)
  let a:ctx.content = l:contents.content
  let a:ctx.view_content = l:contents.view_content
  call window#util#update_poup_window(a:ctx)
endfunction

" delete image
function! s:delete_image(ctx) abort
  let a:ctx.disable_filter = 1
  let result = input('do you want to delete the image? y/n:')
  let a:ctx.disable_filter = 0
  echo ''

  if result ==# 'y' || result ==# 'Y'
    call docker#api#image#delete(a:ctx, function('docker#image#update_contents'))
  endif
endfunction

" push image
function! s:push_image(ctx) abort
  let a:ctx.disable_filter = 1
  let result = input('do you want to push the image? y/n:')
  let a:ctx.disable_filter = 0
  echo ''

  if result ==# 'y' || result ==# 'Y'
    call docker#api#image#push(a:ctx)
  endif
endfunction

function! s:tag_image(ctx) abort
  let a:ctx.disable_filter = 1
  let repoTag = input('repo and tag name:')
  let a:ctx.disable_filter = 0
  echo ''

  let repoTag = split(repoTag, ':')
  if len(repoTag) == 0
    call docker#util#echo_err('docker.vim: repo and tag name is empty, please input repo and tag name')
    return
  elseif len(repoTag) == 1
    call docker#util#echo_err('docker.vim: repo or tag name is empty, please input repo and tag name')
    return
  elseif len(repoTag) > 2
    call docker#util#echo_err('docker.vim: invalid repo and tag name, please input format that is repo:tag')
    return
  endif

  let repo = repoTag[0]
  let tag = repoTag[1]

  if empty(repo)
    call docker#util#echo_err('docker.vim: repo name is empty, please input repo')
    return
  endif

  if empty(tag)
    call docker#util#echo_err('docker.vim: tag name is empty, please input rag')
    return
  endif

  let a:ctx['newRepo'] = repo
  let a:ctx['newTag'] = tag

  call docker#api#image#tag(a:ctx, function('docker#image#update_contents'))
endfunction

function! s:save_image(ctx) abort
  let a:ctx.disable_filter = 1
  let result = input('tarball name:')
  let a:ctx.disable_filter = 0
  echo ''

  if result ==# ''
    call docker#util#echo_err('docker.vim: please input tarball name')
    return
  endif

  let a:ctx["tarball_name"] = result
  call docker#api#image#save(a:ctx)
endfunction

function! s:load_image(ctx) abort
  let a:ctx.disable_filter = 1
  let result = input('file:')
  let a:ctx.disable_filter = 0
  echo ''

  if result ==# ''
    call docker#util#echo_err('docker.vim: please input file path')
    return
  endif

  let a:ctx["file"] = result
  call docker#api#image#load(a:ctx, function('docker#image#update_contents'))
endfunction

" this is popup window filter function
function! docker#image#functions(ctx, key) abort
  if a:key ==# "\<C-d>"
    call s:delete_image(a:ctx)
  elseif a:key ==# "\<C-r>"
    call popup_close(a:ctx.id)
    call docker#api#container#simple_run(a:ctx)
  elseif a:key ==# 'R'
    call docker#image#update_contents(a:ctx)
  elseif a:key ==# 'r'
    call docker#api#container#run(a:ctx)
  elseif a:key ==# 'p'
    call s:push_image(a:ctx)
  elseif a:key ==# 't'
    call s:tag_image(a:ctx)
  elseif a:key ==# 's'
    call s:save_image(a:ctx)
  elseif a:key ==# 'l'
    call s:load_image(a:ctx)
  elseif a:key ==# "\<CR>"
    call popup_close(a:ctx.id)
    call docker#api#image#inspect(a:ctx)
  endif
endfunction

" pull image
function! docker#image#pull() abort
  let image = input("image name:")
  echo ''
  if image ==# ''
    call docker#util#echo_err('please input command')
    return
  endif
  call docker#api#image#pull(image)
endfunction

" search image
function! s:image_search(term, offset, top) abort
  let l:table = s:TABLE.new({
        \ 'columns': [{},{},{},{},{}],
        \ 'header' : ['NAME',  'DESCRIPTION', 'STARS', 'OFFICIAL', 'AUTOMATED'],
        \ })

  let l:search_images = docker#api#image#search(a:term)

  let l:images = []
  for row in l:search_images
    let des = substitute(row.description, "\\n", ' ', '')
    let image = {
          \ 'name': row.name,
          \ 'description': len(des) > 30 ? des[:30] .. "..." : des,
          \ 'stars': printf("%d", row.star_count),
          \ 'official': row.is_official ? "[OK]" : "",
          \ 'automated': row.is_automated ? "[OK]": ""
          \ }

    call add(l:images, image)

  endfor

  for image in l:images[a:offset: a:offset + a:top - 1]
    call l:table.add_row([
          \ image.name,
          \ image.description,
          \ image.stars,
          \ image.official,
          \ image.automated])
  endfor

  return {'content': l:images,
        \ 'view_content': l:table.stringify(),
        \ }
endfunction

" search image
function! docker#image#search() abort
  let term = input("image name:")
  echo ''
  if term ==# ''
    call docker#util#echo_err('docker.vim: please input image name')
    return
  endif

  let l:maxheight = 15
  let l:top = l:maxheight - 4
  let l:contents = s:image_search(term, 0, l:top)

  if len(l:contents.content) ==# 0
    call docker#util#echo_err('docker.vim: not found images')
    return
  endif

  let l:ctx = { 'type': 'search',
        \ 'title':'[search imgaes]',
        \ 'select':0,
        \ 'highlight_idx': 4,
        \ 'content': l:contents.content,
        \ 'view_content': l:contents.view_content,
        \ 'maxheight': l:maxheight,
        \ 'top': l:top,
        \ 'offset': 0,
        \ 'disable_filter': 0,
        \ 'refresh_timer': 0,
        \ }

  call window#util#create_popup_window(l:ctx)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
