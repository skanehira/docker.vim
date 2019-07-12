# docker.vim
This is docker manager plugin.

![](screenshots/docker.vim.gif)

# Features
## images
- get images
- delete image
- pull image

## containers
- start/stop/restart/kill container
- delete container
- attach container(require docker command)
- monitoring container CPU/MEM

# Requirements
- curl >= 7.40.0
- Vim version >= 8.1.1618
- docker command

# Installation
ex dein.vim
```toml
[[plugins]]
repo = 'skanehira/docker.vim'
```

# Usage
## commands
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

## key bindings
containers

| operation          | key    |
|--------------------|--------|
| start container    | u      |
| stop container     | s      |
| restart container  | r      |
| refresh containers | R      |
| kill container     | K      |
| attach container   | a      |
| delete container   | ctrl-d |
| rename container   | ctrl-r |
| scroll to top      | 0      |
| scroll to bottom   | G      |


images

| operation        | key    |
|------------------|--------|
| refresh images   | R      |
| delete image     | ctrl-d |
| scroll to top    | 0      |
| scroll to bottom | G      |
