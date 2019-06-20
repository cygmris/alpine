FROM alpine:latest

MAINTAINER cygmris <chrisheng86@gmail.com>

#//apk mirror
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

RUN apk update

RUN apk add --virtual operational vim \
        tcpdump
