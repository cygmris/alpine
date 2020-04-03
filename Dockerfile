FROM alpine:latest

MAINTAINER cygmris <chrisheng86@gmail.com>

#//apk mirror
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

RUN apk update

RUN apk add --no-cache  --virtual operational \
        vim \
        tcpdump \
        zsh \
        git
        
RUN apk add --no-cache  --virtual utils \
        wget \
        curl

RUN apk add --no-cache \
        bash

RUN sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
RUN echo 'export PROMPT="%{$fg_bold[white]%}%M %{$fg_bold[red]%}➜ %{$fg_bold[green]%}%p %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}"' >> ~/.zshrc

# RUN sed "s#/root:/bin/ash#/root:/bin/zsh/#"  /etc/passwd

CMD [ "/bin/zsh" ]
