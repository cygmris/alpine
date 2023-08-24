FROM alpine:3.18.3

ENV TZ=Asia/Hong_Kong
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apk update

RUN apk add --no-cache  --virtual operational \
        vim \
        tcpdump \
        git \
        zsh \
        bash
        
RUN apk add --no-cache  --virtual utils \
        wget \
        libressl-dev \
        ca-certificates \
        libcurl \
        curl

RUN sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
RUN echo 'export PROMPT="%{$fg_bold[white]%}%M %{$fg_bold[red]%}➜ %{$fg_bold[green]%}%p %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}"' >> ~/.zshrc


ENV NGINX_VERSION=1.25.2
ENV NJS_VERSION=0.8.0
ENV PKG_RELEASE=1

ARG CN=0
ENV CN=$CN
RUN printf "CN: $CN \n"; if [ "$CN" == "1" ]; then printf "using apk China Mirror..\n"; sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories; else printf "normally without apk mirror\n"; fi
RUN apk update
# RUN apk add --no-cache --repository https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/community gnu-libiconv

# copy from official image

RUN set -x \
    && apkArch="$(cat /etc/apk/arch)" \
    && nginxPackages=" \
        nginx=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-xslt=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-geoip=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-image-filter=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-perl=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-njs=${NGINX_VERSION}.${NJS_VERSION}-r${PKG_RELEASE} \
    " \
# install prerequisites for public key and pkg-oss checks
    && apk add --no-cache --virtual .checksum-deps \
        openssl \
    && case "$apkArch" in \
        x86_64|aarch64) \
# arches officially built by upstream
            set -x \
            && KEY_SHA512="e09fa32f0a0eab2b879ccbbc4d0e4fb9751486eedda75e35fac65802cc9faa266425edf83e261137a2f4d16281ce2c1a5f4502930fe75154723da014214f0655" \
            && wget -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
            && if echo "$KEY_SHA512 */tmp/nginx_signing.rsa.pub" | sha512sum -c -; then \
                echo "key verification succeeded!"; \
                mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
            else \
                echo "key verification failed!"; \
                exit 1; \
            fi \
            && apk add -X "https://nginx.org/packages/mainline/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" --no-cache $nginxPackages \
            ;; \
        *) \
# we're on an architecture upstream doesn't officially build for
# let's build binaries from the published packaging sources
            set -x \
            && tempDir="$(mktemp -d)" \
            && chown nobody:nobody $tempDir \
            && apk add --no-cache --virtual .build-deps \
                gcc \
                libc-dev \
                make \
                openssl-dev \
                pcre2-dev \
                zlib-dev \
                linux-headers \
                perl-dev \
                bash \
                alpine-sdk \
                findutils \
            && su nobody -s /bin/sh -c " \
                export HOME=${tempDir} \
                && cd ${tempDir} \
                && curl -f -O https://hg.nginx.org/pkg-oss/archive/${NGINX_VERSION}-${PKG_RELEASE}.tar.gz \
                && PKGOSSCHECKSUM=\"64d3f504b246df1997d8442b12303944d2f51e09b35443b23da479af7790b9f84cf2ddf8ba108bdd712f92466f9a8e107b865a488f0898b87d39059f9f7ff56c *${NGINX_VERSION}-${PKG_RELEASE}.tar.gz\" \
                && if [ \"\$(openssl sha512 -r ${NGINX_VERSION}-${PKG_RELEASE}.tar.gz)\" = \"\$PKGOSSCHECKSUM\" ]; then \
                    echo \"pkg-oss tarball checksum verification succeeded!\"; \
                else \
                    echo \"pkg-oss tarball checksum verification failed!\"; \
                    exit 1; \
                fi \
                && tar xzvf ${NGINX_VERSION}-${PKG_RELEASE}.tar.gz \
                && cd pkg-oss-${NGINX_VERSION}-${PKG_RELEASE} \
                && cd alpine \
                && make module-perl \
                && apk index -o ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz ${tempDir}/packages/alpine/${apkArch}/*.apk \
                && abuild-sign -k ${tempDir}/.abuild/abuild-key.rsa ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz \
                " \
            && cp ${tempDir}/.abuild/abuild-key.rsa.pub /etc/apk/keys/ \
            && apk del --no-network .build-deps \
            && apk add -X ${tempDir}/packages/alpine/ --no-cache $nginxPackages \
            ;; \
    esac \
# remove checksum deps
    && apk del --no-network .checksum-deps \
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
    && if [ -f "$tempDir" ]; then rm -rf "$tempDir"; fi \
    && if [ -f "/etc/apk/keys/abuild-key.rsa.pub" ]; then rm -f /etc/apk/keys/abuild-key.rsa.pub; fi \
    && if [ -f "/etc/apk/keys/nginx_signing.rsa.pub" ]; then rm -f /etc/apk/keys/nginx_signing.rsa.pub; fi \
# Bring in gettext so we can get `envsubst`, then throw
# the rest away. To do this, we need to install `gettext`
# then move `envsubst` out of the way so `gettext` can
# be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del --no-network .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
# Bring in tzdata so users could set the timezones through the environment
# variables
    && apk add --no-cache tzdata \
# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
# create a docker-entrypoint.d directory
    && mkdir /docker-entrypoint.d


RUN apk add --virtual processmgmt --no-cache \
  supervisor \
  python3 \
  python3-dev \
  py3-pip \
  && mkdir -p /var/log/supervisor


RUN apk add --no-cache --virtual .build-deps gcc libc-dev libffi-dev

RUN pip3 install -U pip \
  && pip3 install -U certbot \
  && mkdir -p /etc/letsencrypt/webrootauth

RUN apk del .build-deps


RUN mkdir -p /etc/supervisor/conf.d
ADD supervisord.conf /etc/supervisord.conf
COPY supervisor.conf.d/nginx.conf /etc/supervisor/conf.d/
# Copy our nginx config
# RUN rm -Rf /etc/nginx/nginx.conf
ADD nginx/nginx.conf /etc/nginx/nginx.conf

# nginx site conf
RUN mkdir -p /etc/nginx/sites-available/ && \
  mkdir -p /etc/nginx/sites-enabled/ && \
  mkdir -p /etc/nginx/ssl/ && \
  rm -Rf /var/www/* && \
  mkdir -p /var/www/html/

# Add Scripts
COPY scripts/start.sh /
COPY scripts/docker-entrypoint.sh /
COPY scripts/10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY scripts/15-local-resolvers.envsh /docker-entrypoint.d
COPY scripts/20-envsubst-on-templates.sh /docker-entrypoint.d
COPY scripts/30-tune-worker-processes.sh /docker-entrypoint.d
COPY scripts/pull /usr/bin/pull
COPY scripts/push /usr/bin/push
COPY scripts/letsencrypt-setup /usr/bin/letsencrypt-setup
COPY scripts/letsencrypt-renew /usr/bin/letsencrypt-renew
COPY nginx/templates /etc/nginx/templates

# copy in code
ADD src/ /var/www/html/
ADD errors/ /var/www/errors

RUN chown -Rf nginx.nginx /var/www/html
VOLUME "/var/www/html"

EXPOSE 443 80


ENV REAL_IP_FROM=172.16.0.0/12
ENV NGINX_LISTEN_PORT=80
ENV BACKEND_URI=http://backend-svc
ENV PROXY_HTTP_VERSION=1.1


STOPSIGNAL SIGTERM
WORKDIR /var/www/html

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/start.sh"]
