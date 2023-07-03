# Enable shell debugging
set -x

# Add nginx group and user
addgroup -g 101 -S nginx
adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Determine the architecture of the apk package
apkArch="$(cat /etc/apk/arch)"

# Define nginx packages to install
nginxPackages="
nginx=${NGINX_VERSION}-r${PKG_RELEASE}
nginx-module-xslt=${NGINX_VERSION}-r${PKG_RELEASE}
nginx-module-geoip=${NGINX_VERSION}-r${PKG_RELEASE}
nginx-module-image-filter=${NGINX_VERSION}-r${PKG_RELEASE}
nginx-module-njs=${NGINX_VERSION}.${NJS_VERSION}-r${PKG_RELEASE}
"

# Check architecture and perform different steps accordingly
case "$apkArch" in
x86_64)
    set -x
    
    # Define the SHA512 key
    KEY_SHA512="e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a *stdin"
    
    # Add openssl for certificate dependencies
    apk add --no-cache --virtual .cert-deps openssl
    
    # Download the Nginx public key and verify it
    wget -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub
    if [ "$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout | openssl sha512 -r)" = "$KEY_SHA512" ]; then
        echo "key verification succeeded!"
        mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/
    else
        echo "key verification failed!"
        exit 1
    fi
    
    # Remove certificate dependencies
    apk del .cert-deps
    
    # Add Nginx packages
    apk add -X "https://nginx.org/packages/mainline/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" --no-cache $nginxPackages
    ;;
*)
    set -x
    
    # Create a temporary directory
    tempDir="$(mktemp -d)"
    chown nobody:nobody $tempDir
    
    # Build and install Nginx from source
    apk add --no-cache --virtual .build-deps gcc libc-dev make openssl-dev pcre-dev zlib-dev linux-headers libxslt-dev gd-dev geoip-dev perl-dev libedit-dev mercurial bash alpine-sdk findutils
    su nobody -s /bin/sh -c "
    export HOME=${tempDir}
    cd ${tempDir}
    hg clone https://hg.nginx.org/pkg-oss
    cd pkg-oss
    hg up ${NGINX_VERSION}-${PKG_RELEASE}
    cd alpine
    make all
    apk index -o ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz ${tempDir}/packages/alpine/${apkArch}/*.apk
    abuild-sign -k ${tempDir}/.abuild/abuild-key.rsa ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz
    "
    
    # Copy the signing key and install Nginx
    cp ${tempDir}/.abuild/abuild-key.rsa.pub /etc/apk/keys/
    apk del .build-deps
    apk add -X ${tempDir}/packages/alpine/ --no-cache $nginxPackages
    ;;
esac

# Clean up temporary directory and keys
if [ -n "$tempDir" ]; then rm -rf "$tempDir"; fi
if [ -n "/etc/apk/keys/abuild-key.rsa.pub" ]; then rm -f /etc/apk/keys/abuild-key.rsa.pub; fi
if [ -n "/etc/apk/keys/nginx_signing.rsa.pub" ]; then rm -f /etc/apk/keys/nginx_signing.rsa.pub; fi

# Install gettext for i18n support
apk add --no-cache --virtual .gettext gettext

# Move envsubst (for substituting environment variables) and identify its dependencies
mv /usr/bin/envsubst /tmp/
runDeps="$(scanelf --needed --nobanner /tmp/envsubst | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | sort -u | xargs -r apk info --installed | sort -u)"

# Install dependencies and move envsubst back
apk add --no-cache $runDeps
apk del .gettext
mv /tmp/envsubst /usr/local/bin/

# Install timezone data
apk add --no-cache tzdata

# Redirect Nginx logs to stdout and stderr for Docker logging
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log
