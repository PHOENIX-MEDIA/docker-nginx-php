FROM alpine:3.21

# An (optional) host that relays your msgs
ENV RELAYHOST=
# An (optional) username for the relay server
ENV RELAYHOST_USERNAME=
# An (optional) login password for the relay server
ENV RELAYHOST_PASSWORD=

# (optional) Should the postfix relay use TLS
ENV SMTP_USE_TLS=

# Fixes an bug with iconv @see https://github.com/docker-library/php/issues/240
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv==1.15-r3
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN apk --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ add \
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
        postfix \
        unzip \
        php82 \
        php82-bcmath \
        php82-ctype \
        php82-curl \
        php82-dom \
        php82-fpm \
        php82-fileinfo \
        php82-gd \
        php82-iconv \
        php82-intl \
        php82-json \
        php82-mbstring \
        php82-common \
        php82-mysqlnd \
        php82-opcache \
        php82-openssl \
        php82-pcntl \
        php82-pecl-apcu \
        php82-pecl-lzf \
        php82-pecl-zstd \
        php82-pdo \
        php82-pdo_mysql \
        php82-phar \
        php82-posix \
        php82-redis \
        php82-session \
        php82-simplexml \
        php82-soap \
        php82-sodium \
        php82-sockets \
        php82-tokenizer \
        php82-xml \
        php82-xmlreader \
        php82-xmlwriter \
        php82-xsl \
        php82-zip \
        && addgroup nginx postdrop && postalias /etc/postfix/aliases && mkdir /var/log/postfix \
        && sed -i '/Include files with config snippets into the root context/,+1d' /etc/nginx/nginx.conf \
        && sed -ie "s#include /etc/nginx/http.d/#include /etc/nginx/conf.d/#g" /etc/nginx/nginx.conf \
        && postconf "smtputf8_enable = no" && postconf "maillog_file=/var/log/postfix/mail.log" \
        && mkdir /var/www/html && chown nginx:nginx /var/www/html \
        && ln -sf /usr/bin/php82 /usr/bin/php \
        && ln -sf /dev/stdout /var/log/nginx/access.log \
        && ln -sf /dev/stderr /var/log/nginx/error.log


COPY conf/www.conf /etc/php82/php-fpm.d/www.conf
COPY conf/default.conf conf/healthz.conf /etc/nginx/conf.d/
COPY healthz /var/www/healthz
COPY bin/setup.sh /setup.sh
COPY bin/run.sh /run.sh
COPY conf/supervisord.conf /etc/supervisord.conf
COPY --from=composer:2.2 /usr/bin/composer /usr/bin/composer

EXPOSE 80

WORKDIR /var/www/html

CMD ["/run.sh"]

