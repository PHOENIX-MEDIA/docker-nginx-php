FROM alpine:3.20

RUN printf "https://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community\nhttps://dl-cdn.alpinelinux.org/alpine/edge/testing\n" > /etc/apk/repositories

# update apk repositories & upgrade all
RUN apk update && apk upgrade

ARG UID=1001
ARG GID=1001

RUN  set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup -g $GID -S nginx \
    && adduser -S -D -H -u $UID -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && apk --no-cache add \
        ca-certificates \
        gettext \
        bash \
        curl \
        rsync \
        sudo \
        git \
        icu-data-full \
        libmcrypt \
        nginx \
        supervisor \
        shadow \
        unzip \
        patch \
        nodejs \
        npm \
        php83 \
        php83-bcmath \
        php83-ctype \
        php83-curl \
        php83-dom \
        php83-fpm \
        php83-fileinfo \
        php83-gd \
        php83-iconv \
        php83-intl \
        php83-json \
        php83-mbstring \
        php83-common \
        php83-mysqlnd \
        php83-opcache \
        php83-openssl \
        php83-pcntl \
        php83-pecl-apcu \
        php83-pecl-lzf \
        php83-pecl-zstd \
        php83-pdo \
        php83-pdo_mysql \
        php83-phar \
        php83-posix \
        php83-redis \
        php83-session \
        php83-simplexml \
        php83-soap \
        php83-sodium \
        php83-sockets \
        php83-tokenizer \
        php83-xml \
        php83-xmlreader \
        php83-xmlwriter \
        php83-xsl \
        php83-zip \
    && sed -i '/Include files with config snippets into the root context/,+1d' /etc/nginx/nginx.conf \
    && sed -ie "s#include /etc/nginx/http.d/#include /etc/nginx/conf.d/#g" /etc/nginx/nginx.conf \
    && mkdir /var/www/html && chown nginx:nginx /var/www/html \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Add v8js
RUN apk add --no-cache nodejs-dev php83-dev alpine-sdk
RUN mkdir /usr/local/include && cp -rs /usr/include/node/* /usr/local/include/
COPY patches/v8js_php8-libnode.patch /tmp/v8js_php8-libnode.patch
WORKDIR /tmp
RUN git clone https://github.com/phpv8/v8js.git --branch php8
WORKDIR /tmp/v8js
RUN git apply /tmp/v8js_php8-libnode.patch
RUN phpize && ./configure && make && make test \
    && cp -v modules/v8js.* `php -r "echo ini_get('extension_dir');"` \
    && rm -rf /tmp/v8js && rm /tmp/v8js_php8-libnode.patch
COPY conf/00_v8js.ini /etc/php83/conf.d/00_v8js.ini
RUN php --ri v8js

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY conf/default.conf conf/healthz.conf /etc/nginx/conf.d/
COPY healthz /var/www/healthz
COPY bin/setup.sh /setup.sh
COPY bin/run.sh /run.sh
COPY conf/supervisord.conf /etc/supervisord.conf
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

EXPOSE 80

WORKDIR /var/www/html

CMD ["/run.sh"]
