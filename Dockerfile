FROM alpine:3.10.2 as fetch_docker
ENV DOCKER_VERSION=19.03.2
WORKDIR /root
RUN apk --no-cache --update add curl && \
	curl -O https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz && \
	tar xvzf docker-${DOCKER_VERSION}.tgz && \
	rm -f docker-${DOCKER_VERSION}.tgz

FROM alpine:3.10.2 as fetch_vim_iceberg
WORKDIR /root
RUN apk --no-cache --update add git && \
	git clone https://github.com/cocopon/iceberg.vim.git

FROM thinca/vim

ENV TERM xterm-256color
RUN apk --no-cache --update add curl

COPY . /root/.vim/pack/plugins/start/docker.vim
COPY vimrc /root/.vimrc

# COPY from other stages at last for concurrent building using BuildKit
COPY --from=fetch_docker /root/docker/docker /usr/local/bin/
COPY --from=fetch_vim_iceberg /root/iceberg.vim/colors /root/.vim/colors

ENTRYPOINT ["vim"]
