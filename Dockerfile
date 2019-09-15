FROM alpine:3.10.2 as build_stage
WORKDIR /root
RUN apk --no-cache update && apk add curl git && \
	curl -O https://download.docker.com/linux/static/stable/x86_64/docker-19.03.2.tgz && \
	tar xvzf docker-19.03.2.tgz && \
	git clone https://github.com/cocopon/iceberg.vim.git

FROM thinca/vim
COPY --from=build_stage /root/docker/docker /usr/local/bin/
COPY --from=build_stage /root/iceberg.vim/colors /root/.vim/colors

ENV TERM xterm-256color
RUN apk --no-cache update && apk add curl

ADD ./ /root/.vim/pack/plugins/start/docker.vim
ADD ./vimrc /root/.vimrc

ENTRYPOINT ["vim"]
