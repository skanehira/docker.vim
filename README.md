# docker.vim
This is management plugin for docker.

![](screenshots/docker.vim.gif)

# Features
## images
- image list(udpate every 5 second)
- delete image
- pull image
- search image
- open DockerHub in browser

## containers
- container list(udpate every 5 second)
- start/stop/restart/kill container
- delete container
- attach container(require docker cli)
- run container(like docker run {container})
- monitoring container logs and CPU/MEM

# Requirements
- curl >= 7.40.0
- Vim version >= 8.1.1799
- docker cli

# Installation
e.g dein.vim

```toml
[[plugins]]
repo = 'skanehira/docker.vim'
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

| key    | operation                             |
|--------|---------------------------------------|
| u      | start container                       |
| s      | stop container                        |
| r      | restart container                     |
| R      | refresh containers                    |
| K      | kill container                        |
| a      | attach container                      |
| a      | monitor container's cpu nad mem usage |
| ctrl-d | delete container                      |
| ctrl-r | rename container                      |
| l      | monitoring container logs             |
| /      | start filter mode                     |

### images

| key    | operation         |
|--------|-------------------|
| R      | refresh images    |
| r      | run container     |
| ctrl-d | delete image      |
| /      | start filter mode |

### search images

| key | operation                 |
|-----|---------------------------|
| p   | pull image                |
| o   | open DockerHub in browser |

