# docker.vim [![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)

This is management plugin for docker.

![](https://imgur.com/5h1FufL.gif)

# Features
## images
- image list(udpate every 5 second)
- delete image
- pull image
- search image
- open DockerHub in browser
- push an image
- tag an image

## containers
- container list(udpate every 5 second)
- start/stop/restart/kill container
- delete container
- attach container
- run container(like docker run {container})
- monitoring container logs and CPU/MEM
- copy file/folders between containers and local filesystem

## others
- monitoring docker engine's events

# Requirements
- curl >= 7.40.0
- Vim version >= 8.1.1799
- docker cli

# Installation
e.g using dein.vim

```toml
[[plugins]]
repo = 'skanehira/docker.vim'
```

e.g using docker

```sh
$ docker run --rm -itv /var/run/docker.sock:/var/run/docker.sock skanehira/docker.vim
```

# Usage
## settings
```vim
" open browser command, deafult is 'open'
let g:docker_open_browser_cmd = 'open'

" split temrinal windows, can use vert or tab, etc...
" see :h vert
let g:docker_terminal_open = 'bo'

" check plugin's version when plugin loading.
" default is checking.
" If you not want to check, please set 0 to this option.
let g:docker_plugin_version_check = 1

" this is registry auth info.
" if you want to push an image, please set your auth info.
let g:docker_registry_auth = {
	\ 'username': 'your name',
	\ 'password': 'your password',
	\ 'email': 'your email',
	\ 'serveraddress': 'https://index.docker.io/v1/',
	\ }

```

## commands
docker wrap command

```vim
" result will display in terminal buffer.
:Docker ps -a
```

images
```vim
:DockerImages
```

pull image
```vim
:DockerImagePull
```

conatiners
```vim
:DockerContainers
```

monitor container
```vim
" start monitor
:DockerMonitorStart {id or name}

" stop monitor
:DockerMonitorStop
```

monitor window move
```vim
:DockerMonitorWindowMove
```

monitoring container logs
```vim
" if contaienr is not running, terminal does not close automatically
:DockerContainerLogs {id or name}
```

monitoring docker engine's events
```vim
:DockerEvents
```

show version info
```vim
:DockerVersion
```

## key bindings
### common operations in popup window.

| key | operation          |
|-----|--------------------|
| 0   | scroll to top      |
| G   | scroll to bottom   |
| q   | close popup window |

### containers

| key    | operation                                                  |
|--------|------------------------------------------------------------|
| u      | start container                                            |
| s      | stop container                                             |
| r      | restart container                                          |
| R      | refresh containers                                         |
| K      | kill container                                             |
| a      | attach container                                           |
| m      | monitor container's cpu nad mem usage                      |
| ctrl-d | delete container                                           |
| ctrl-r | rename container                                           |
| l      | monitoring container logs                                  |
| /      | start filter mode                                          |
| ctrl-^ | switch to images popup window                              |
| c      | copy file/folters between containers and local file system |

### images

| key    | operation                         |
|--------|-----------------------------------|
| R      | refresh images                    |
| r      | run container                     |
| ctrl-d | delete image                      |
| /      | start filter mode                 |
| ctrl-^ | switch to containers popup window |
| t      | tag an image                      |

### search images

| key | operation                 |
|-----|---------------------------|
| p   | pull image                |
| o   | open DockerHub in browser |

