# https://hg.nginx.org/nginx/file/tip/src/core/nginx.h
ARG NGINX_VERSION=1.27.4

# https://hg.nginx.org/nginx/
ARG NGINX_COMMIT=cfa2aef9a28c

# https://github.com/google/ngx_brotli
ARG NGX_BROTLI_COMMIT=a71f9312c2deb28875acc7bacfdd5695a111aa53

# https://github.com/nginx/njs/releases/tag/0.8.7
ARG NJS_COMMIT=ba6b9e157ef472dbcac17e32c55f3227daa3103c

# https://github.com/openresty/headers-more-nginx-module#installation
ARG HEADERS_MORE_VERSION=0.37

# https://github.com/leev/ngx_http_geoip2_module/releases
ARG GEOIP2_VERSION=3.4

# https://github.com/tokers/zstd-nginx-module/releases
ARG ZSTD_VERSION=0.1.1

# NGINX UID / GID
ARG NGINX_USER_UID=100
ARG NGINX_GROUP_GID=101

# https://nginx.org/en/docs/http/ngx_http_v3_module.html
# https://nginx.org/en/docs/configure.html
# Removed NJS module from configuration
ARG CONFIG="\
	--build=$NGINX_COMMIT \
	--prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--modules-path=/usr/lib/nginx/modules \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx/nginx.pid \
	--lock-path=/var/run/nginx/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-http_auth_request_module \
	--with-http_xslt_module=dynamic \
	--with-http_image_filter_module=dynamic \
	--with-http_geoip_module=dynamic \
	--with-http_perl_module=dynamic \
	--with-threads \
	--with-stream \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
	--with-stream_realip_module \
	--with-stream_geoip_module=dynamic \
	--with-http_slice_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-compat \
	--with-file-aio \
	--with-http_v2_module \
	--with-http_v3_module \
	--with-openssl-opt=enable-ktls \
	--add-module=/usr/src/ngx_brotli \
	--add-module=/usr/src/headers-more-nginx-module-$HEADERS_MORE_VERSION \
	--add-module=/usr/src/zstd \
	--add-dynamic-module=/usr/src/ngx_http_geoip2_module \
	"

FROM alpine:3.20 AS base

ARG NGINX_VERSION
ARG NGINX_COMMIT
ARG NGX_BROTLI_COMMIT
ARG HEADERS_MORE_VERSION
ARG GEOIP2_VERSION
ARG ZSTD_VERSION
ARG NGINX_USER_UID
ARG NGINX_GROUP_GID
ARG CONFIG

RUN \
	apk add --no-cache --virtual .build-deps \
	gcc \
	gd-dev \
	geoip-dev \
	gnupg \
	go \
	libc-dev \
	libxslt-dev \
	linux-headers \
	make \
	mercurial \
	musl-dev \
	ninja \
	openssl-dev \
	pcre-dev \
	perl-dev \
	zlib-dev \
	&& apk add --no-cache --virtual .brotli-build-deps \
	autoconf \
	automake \
	cmake \
	g++ \
	git \
	libtool \
	&& apk add --no-cache --virtual .geoip2-build-deps \
	libmaxminddb-dev \
	&& apk add --no-cache --virtual .zstd-build-deps \
	zstd-dev \
	&& git config --global init.defaultBranch master

WORKDIR /usr/src/

RUN \
	echo "Cloning nginx $NGINX_VERSION (rev $NGINX_COMMIT from 'default' branch) ..." \
	&& hg clone -b default --rev $NGINX_COMMIT https://hg.nginx.org/nginx/ /usr/src/nginx-$NGINX_VERSION

RUN \
	echo "Cloning brotli $NGX_BROTLI_COMMIT ..." \
	&& mkdir /usr/src/ngx_brotli \
	&& cd /usr/src/ngx_brotli \
	&& git init \
	&& git remote add origin https://github.com/google/ngx_brotli.git \
	&& git fetch --depth 1 origin $NGX_BROTLI_COMMIT \
	&& git checkout --recurse-submodules -q FETCH_HEAD \
	&& git submodule update --init --depth 1

RUN \
	echo "Downloading headers-more-nginx-module ..." \
	&& cd /usr/src \
	&& wget -q https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v${HEADERS_MORE_VERSION}.tar.gz -O headers-more-nginx-module.tar.gz \
	&& tar -xf headers-more-nginx-module.tar.gz

RUN \
	echo "Downloading ngx_http_geoip2_module ..." \
	&& git clone --depth 1 --branch ${GEOIP2_VERSION} https://github.com/leev/ngx_http_geoip2_module /usr/src/ngx_http_geoip2_module

RUN \
	echo "Downloading zstd-nginx-module ..." \
	&& git clone --depth 1 --branch ${ZSTD_VERSION} https://github.com/tokers/zstd-nginx-module.git /usr/src/zstd

# Build a dummy njs executable to satisfy the later stages
RUN \
	echo "#!/bin/sh" > /usr/sbin/njs \
	&& echo "echo 'NJS version: dummy, not functional'" >> /usr/sbin/njs \
	&& chmod +x /usr/sbin/njs

# Build NGINX
ARG CC_OPT='-g -O2 -flto=auto -ffat-lto-objects'
ARG LD_OPT='-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects'

RUN \
	echo "Building nginx..." \
	&& mkdir -p /var/run/nginx/ \
	&& cd /usr/src/nginx-$NGINX_VERSION \
	&& ./auto/configure $CONFIG --with-cc-opt="$CC_OPT" --with-ld-opt="$LD_OPT" \
	&& make -j"$(getconf _NPROCESSORS_ONLN)"

RUN \
	cd /usr/src/nginx-$NGINX_VERSION \
	&& make install \
	&& rm -rf /etc/nginx/html/ \
	&& mkdir /etc/nginx/conf.d/ \
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
	\
	# https://tools.ietf.org/html/rfc7919
	# https://github.com/mozilla/ssl-config-generator/blob/master/docs/ffdhe2048.txt
	&& wget -q https://ssl-config.mozilla.org/ffdhe2048.txt -O /etc/ssl/dhparam.pem \
	\
	# Bring in gettext so we can get `envsubst`, then throw
	# the rest away. To do this, we need to install `gettext`
	# then move `envsubst` out of the way so `gettext` can
	# be deleted completely, then move `envsubst` back.
	&& apk add --no-cache --virtual .gettext gettext \
	\
	&& scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /usr/bin/envsubst \
	| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
	| sort -u \
	| xargs -r apk info --installed \
	| sort -u > /tmp/runDeps.txt

FROM alpine:3.20
ARG NGINX_VERSION
ARG NGINX_COMMIT
ARG NGINX_USER_UID
ARG NGINX_GROUP_GID

ENV NGINX_VERSION=$NGINX_VERSION
ENV NGINX_COMMIT=$NGINX_COMMIT

RUN \
	apk add --no-cache \
	bash \
	bash-completion \
	busybox-suid \
	certbot \
	certbot-nginx \
	curl \
	net-tools \
	sudo \
	vim \
	# Add crond for certificate renewal
	dcron

COPY --from=base /var/run/nginx/ /var/run/nginx/
COPY --from=base /tmp/runDeps.txt /tmp/runDeps.txt
COPY --from=base /etc/nginx /etc/nginx
COPY --from=base /usr/lib/nginx/modules/*.so /usr/lib/nginx/modules/
COPY --from=base /usr/sbin/nginx /usr/sbin/
COPY --from=base /usr/local/lib/perl5/site_perl /usr/local/lib/perl5/site_perl
COPY --from=base /usr/bin/envsubst /usr/local/bin/envsubst
COPY --from=base /etc/ssl/dhparam.pem /etc/ssl/dhparam.pem

COPY --from=base /usr/sbin/njs /usr/sbin/njs

RUN \
	addgroup --gid $NGINX_GROUP_GID -S nginx \
	&& adduser --uid $NGINX_USER_UID -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
	&& apk add --no-cache --virtual .nginx-rundeps tzdata $(cat /tmp/runDeps.txt) \
	&& rm /tmp/runDeps.txt \
	&& ln -s /usr/lib/nginx/modules /etc/nginx/modules \
	# forward request and error logs to docker log collector
	&& mkdir /var/log/nginx \
	&& touch /var/log/nginx/access.log /var/log/nginx/error.log \
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf
COPY ssl_common.conf /etc/nginx/conf.d/ssl_common.conf

# show env
RUN env | sort

# njs version
RUN /usr/sbin/njs -v || echo "NJS dummy version check"

# test the configuration
RUN nginx -V; nginx -t

EXPOSE 80 443 8888 8889

STOPSIGNAL SIGTERM

USER nginx
CMD [ "nginx", "-g", "daemon off;" ]
#CMD ["/usr/local/bin/start.sh"]
