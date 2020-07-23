# docker.vim [![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)

This is management plugin for docker.

If you want to manage docker-compose, you can use [docker-compose.vim](https://github.com/skanehira/docker-compose.vim).

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
- build an image
- save an image to tarball
- inspect an image
- quick run container(like `docker run -it`)

## containers
- container list(udpate every 5 second)
- start/stop/restart/kill container
- delete container
- attach container
- run container(like docker run {container})
- monitoring container logs and CPU/MEM
- copy file/folders between containers and local filesystem

## networks
- network list(update every 5 second)

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
	\ 'serveraddress': 'https://docker.io/',
	\ }

" you can also read auth info from json file.
" if you manage vimrc on GitHub, we recommend using json file.
let s:docker_auth_file = expand('~/.docker/docker.vim.json')
let g:docker_registry_auth = \
	json_decode(join(readfile(s:docker_auth_file), "\n"))
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

build an image
```vim
" build an image use Dockerfile
:DockerImageBuild -t {tag_name} .

" build an image use buffer's contents
:'<,'>DockerImageBuild -t {tag_name} -
```

show version info
```vim
:DockerVersion
```

## key bindings
### common operations in popup window.

| key      | operation                    |
|----------|------------------------------|
| `g`      | scroll to top                |
| `G`      | scroll to bottom             |
| `q`      | close popup window           |
| `ctrl-^` | switch to other popup window |

### containers

| key                    | operation                                                  |
|------------------------|------------------------------------------------------------|
| `u`                    | start container                                            |
| `s`                    | stop container                                             |
| `r`                    | restart container                                          |
| `R`                    | refresh containers                                         |
| `K`                    | kill container                                             |
| `a`                    | attach container                                           |
| `m`                    | monitor container's cpu nad mem usage                      |
| `ctrl-d`               | delete container                                           |
| `ctrl-r`               | rename container                                           |
| `l`                    | monitoring container logs                                  |
| `/`                    | start filter mode                                          |
| `p`                    | switch to images popup window                              |
| `c`                    | copy file/folters between containers and local file system |
| `C`                    | create a new image from container                          |
| `<CR>` (same as Enter) | inspect a container                                        |

### images

| key                    | operation                                  |
|------------------------|--------------------------------------------|
| `R`                    | refresh images                             |
| `r`                    | run container                              |
| `ctrl-d`               | delete image                               |
| `ctrl-r`               | quick run container(like `docker run -it`) |
| `/`                    | start filter mode                          |
| `t`                    | tag an image                               |
| `s`                    | save an image to tarball                   |
| `l`                    | load an image from tarball                 |
| `<CR>` (same as Enter) | inspect an image                           |

### networks
| key                    | operation         |
|------------------------|-------------------|
| `<CR>` (same as Enter) | inspect a network |

### search images

| key | operation                 |
|-----|---------------------------|
| `p` | pull image                |
| `o` | open DockerHub in browser |

