" docker.vim
" Author : skanehira <sho19921005@gmail.com>
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

" async http get
function! docker#api#http#async_get(use_socket, url, param, callback) abort
  let setting = {
        \ 'use_socket': a:use_socket,
        \ 'url': a:url,
        \ 'method': 'GET',
        \ 'param': a:param,
        \ 'callback': a:callback,
        \ }

  call s:async_request(setting)
endfunction

" async http post
function! docker#api#http#async_post(use_socket, url, param, header, data, callback) abort
  let setting = {
        \ 'use_socket': a:use_socket,
        \ 'url': a:url,
        \ 'method': 'POST',
        \ 'param': a:param,
        \ 'header': a:header,
        \ 'data': a:data,
        \ 'callback': a:callback,
        \ }

  call s:async_request(setting)
endfunction

" async http delete
function! docker#api#http#async_delete(use_socket, url, param, callback) abort
  let setting = {
        \ 'use_socket': a:use_socket,
        \ 'url': a:url,
        \ 'method': 'DELETE',
        \ 'param': a:param,
        \ 'callback': a:callback,
        \ }

  call s:async_request(setting)
endfunction

" async http request function
" setting object
" {
"   'use_socket': 1,
"   'url': 'http://localhost',
"  'method': 'POST',
"  'param' : {
"    \ 'name': 'gorilla',
"    \ 'age' : 26,
"    \ },
"  'header': {
"    \ 'is_human': false,
"    \ },
"  'data' : {
"    \ 'name': 'gorilla',
"    \ 'age' : 26,
"    \ },
"  'callback': function('<SNR>_88_gorilla_cb'),
" }
function! s:async_request(setting) abort
  let command = []
  if a:setting.use_socket
    let command = ['curl', '-s', '--unix-socket', '/var/run/docker.sock', '-X', a:setting.method]
  else
    let command = ['curl', '-s', '-X', a:setting.method]
  endif

  let dump = {
        \ 'header': s:tempname(),
        \ 'body': s:tempname(),
        \ }

  let quote = s:quote()

  let command += ['--dump-header', dump.header]
  let command += ['--output' , dump.body]

  if has_key(a:setting, 'header') && !empty(a:setting.header)
    for h in items(a:setting.header)
      let command = command +  ['-H', join(h, ':')]
    endfor
  endif

  if has_key(a:setting, 'param') && !empty(a:setting.param)
    let idx = 0
    let url = a:setting.url
    for p in items(a:setting.param)
      if idx ==# 0
        let url = url .. '?' .. join(p, '=')
      else
        let url = url .. '&' .. join(p, '=')
      endif
      let idx += 1
    endfor
    call add(command,  url)
  else
    call add(command,  a:setting.url)
  endif

  if has_key(a:setting, 'data') && !empty(a:setting.data)
    let command += ['-d', json_encode(a:setting.data)]
  endif

  call job_start(command, {
        \ 'err_cb': function('s:request_err_cb'),
        \ 'exit_cb': function('s:request_exit_cb', [dump, a:setting.callback]),
        \ })

endfunction

" job exit callback
function! s:request_exit_cb(dump, callback, ch, status) abort
  if a:status !=# 0
    call docker#util#echo_err(s:errcode[a:status])
    return
  endif
  let response = s:build_response(s:readfile(a:dump.header), s:readfile(a:dump.body))

  " delete dump file
  for file in values(a:dump)
    if filereadable(file)
      call delete(file)
    endif
  endfor

  if empty(response)
    call docker#util#echo_err('docker.vim: cannot get response: body is empty')
    return
  endif

  call call(a:callback, [response])
endfunction

" job error callback
function! s:request_err_cb(ch, msg) abort
  call docker#util#echo_err('docker.vim: ' .. a:msg)
endfunction

" build http response
" response is
" {
"   'status': 200,
"   'headers': {
"     'Date': 'Mon, 15 Jul 2019 01:34:19 GMT',
"     'Content-type': 'application/json',
"   },
"   content: {
"     'name': 'gorilla',
"     'age': 26,
"   },
" }
function! s:build_response(header, body) abort
  let response = {
        \ 'status': 200,
        \ 'headers': {},
        \ 'content': {},
        \ }

  if a:header[0] =~? '^HTTP'
    let response.status = split(a:header[0], ' ')[1]
  else
    call docker#util#echo_err('docker.vim: invalid header: ' .. join(a:header, ' '))
    return {}
  endif

  for head in a:header[1:]
    if head ==# ''
      continue
    endif
    let h = split(head, ':')
    if len(h) ># 1
      let response.headers[trim(h[0])] = trim(h[1])
    else
      let response.headers[trim(h[0])] = ''
    endif
  endfor

  if len(a:body) > 1
    let contents = []

    for content in a:body
      try
        call add(contents, json_decode(content))
      catch
        call add(contents, content)
      endtry
    endfor

    let response.content = contents
  elseif len(a:body) == 1
    try
      let response.content = json_decode(a:body[0])
    catch
      let response.content = a:body[0]
    endtry
  else
    let response.content['message'] = 'docker.vim: empty response body'
  endif

  return response
endfunction

" make a temp file path
function! s:tempname() abort
  return tr(tempname(), '\', '/')
endfunction

" read file
function! s:readfile(file) abort
  if filereadable(a:file)
    return readfile(a:file)
  endif
  return ''
endfunction

" quote
function! s:quote() abort
  return &shell =~# 'sh$' ? "'" : '"'
endfunction

" curl error messages
let s:errcode = {}
let s:errcode[1] = 'Unsupported protocol. This build of curl has no support for this protocol.'
let s:errcode[2] = 'Failed to initialize.'
let s:errcode[3] = 'URL malformed. The syntax was not correct.'
let s:errcode[4] = 'A feature or option that was needed to perform the desired request was not enabled or was explicitly disabled at buildtime. To make curl able to do this, you probably need another build of libcurl!'
let s:errcode[5] = 'Couldn''t resolve proxy. The given proxy host could not be resolved.'
let s:errcode[6] = 'Couldn''t resolve host. The given remote host was not resolved.'
let s:errcode[7] = 'Failed to connect to host.'
let s:errcode[8] = 'FTP weird server reply. The server sent data curl couldn''t parse.'
let s:errcode[9] = 'FTP access denied. The server denied login or denied access to the particular resource or directory you wanted to reach. Most often you tried to change to a directory that doesn''t exist on the server.'
let s:errcode[11] = 'FTP weird PASS reply. Curl couldn''t parse the reply sent to the PASS request.'
let s:errcode[13] = 'FTP weird PASV reply, Curl couldn''t parse the reply sent to the PASV request.'
let s:errcode[14] = 'FTP weird 227 format. Curl couldn''t parse the 227-line the server sent.'
let s:errcode[15] = 'FTP can''t get host. Couldn''t resolve the host IP we got in the 227-line.'
let s:errcode[17] = 'FTP couldn''t set binary. Couldn''t change transfer method to binary.'
let s:errcode[18] = 'Partial file. Only a part of the file was transferred.'
let s:errcode[19] = 'FTP couldn''t download/access the given file, the RETR (or similar) command failed.'
let s:errcode[21] = 'FTP quote error. A quote command returned error from the server.'
let s:errcode[22] = 'HTTP page not retrieved. The requested url was not found or returned another error with the HTTP error code being 400 or above. This return code only appears if -f, --fail is used.'
let s:errcode[23] = 'Write error. Curl couldn''t write data to a local filesystem or similar.'
let s:errcode[25] = 'FTP couldn''t STOR file. The server denied the STOR operation, used for FTP uploading.'
let s:errcode[26] = 'Read error. Various reading problems.'
let s:errcode[27] = 'Out of memory. A memory allocation request failed.'
let s:errcode[28] = 'Operation timeout. The specified time-out period was reached according to the conditions.'
let s:errcode[30] = 'FTP PORT failed. The PORT command failed. Not all FTP servers support the PORT command, try doing a transfer using PASV instead!'
let s:errcode[31] = 'FTP couldn''t use REST. The REST command failed. This command is used for resumed FTP transfers.'
let s:errcode[33] = 'HTTP range error. The range "command" didn''t work.'
let s:errcode[34] = 'HTTP post error. Internal post-request generation error.'
let s:errcode[35] = 'SSL connect error. The SSL handshaking failed.'
let s:errcode[36] = 'FTP bad download resume. Couldn''t continue an earlier aborted download.'
let s:errcode[37] = 'FILE couldn''t read file. Failed to open the file. Permissions?'
let s:errcode[38] = 'LDAP cannot bind. LDAP bind operation failed.'
let s:errcode[39] = 'LDAP search failed.'
let s:errcode[41] = 'Function not found. A required LDAP function was not found.'
let s:errcode[42] = 'Aborted by callback. An application told curl to abort the operation.'
let s:errcode[43] = 'Internal error. A function was called with a bad parameter.'
let s:errcode[45] = 'Interface error. A specified outgoing interface could not be used.'
let s:errcode[47] = 'Too many redirects. When following redirects, curl hit the maximum amount.'
let s:errcode[48] = 'Unknown option specified to libcurl. This indicates that you passed a weird option to curl that was passed on to libcurl and rejected. Read up in the manual!'
let s:errcode[49] = 'Malformed telnet option.'
let s:errcode[51] = 'The peer''s SSL certificate or SSH MD5 fingerprint was not OK.'
let s:errcode[52] = 'The server didn''t reply anything, which here is considered an error.'
let s:errcode[53] = 'SSL crypto engine not found.'
let s:errcode[54] = 'Cannot set SSL crypto engine as default.'
let s:errcode[55] = 'Failed sending network data.'
let s:errcode[56] = 'Failure in receiving network data.'
let s:errcode[58] = 'Problem with the local certificate.'
let s:errcode[59] = 'Couldn''t use specified SSL cipher.'
let s:errcode[60] = 'Peer certificate cannot be authenticated with known CA certificates.'
let s:errcode[61] = 'Unrecognized transfer encoding.'
let s:errcode[62] = 'Invalid LDAP URL.'
let s:errcode[63] = 'Maximum file size exceeded.'
let s:errcode[64] = 'Requested FTP SSL level failed.'
let s:errcode[65] = 'Sending the data requires a rewind that failed.'
let s:errcode[66] = 'Failed to initialise SSL Engine.'
let s:errcode[67] = 'The user name, password, or similar was not accepted and curl failed to log in.'
let s:errcode[68] = 'File not found on TFTP server.'
let s:errcode[69] = 'Permission problem on TFTP server.'
let s:errcode[70] = 'Out of disk space on TFTP server.'
let s:errcode[71] = 'Illegal TFTP operation.'
let s:errcode[72] = 'Unknown TFTP transfer ID.'
let s:errcode[73] = 'File already exists (TFTP).'
let s:errcode[74] = 'No such user (TFTP).'
let s:errcode[75] = 'Character conversion failed.'
let s:errcode[76] = 'Character conversion functions required.'
let s:errcode[77] = 'Problem with reading the SSL CA cert (path? access rights?).'
let s:errcode[78] = 'The resource referenced in the URL does not exist.'
let s:errcode[79] = 'An unspecified error occurred during the SSH session.'
let s:errcode[80] = 'Failed to shut down the SSL connection.'
let s:errcode[82] = 'Could not load CRL file, missing or wrong format (added in 7.19.0).'
let s:errcode[83] = 'Issuer check failed (added in 7.19.0).'
let s:errcode[84] = 'The FTP PRET command failed'
let s:errcode[85] = 'RTSP: mismatch of CSeq numbers'
let s:errcode[86] = 'RTSP: mismatch of Session Identifiers'
let s:errcode[87] = 'unable to parse FTP file list'
let s:errcode[88] = 'FTP chunk callback reported error'
let s:errcode[89] = 'No connection available, the session will be queued'
let s:errcode[90] = 'SSL public key does not matched pinned public key'

let &cpo = s:save_cpo
unlet s:save_cpo
