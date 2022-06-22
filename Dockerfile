FROM alpine:3.15

# An (optional) host that relays your msgs
ENV RELAYHOST=
# An (optional) username for the relay server
ENV RELAYHOST_USERNAME=
# An (optional) login password for the relay server
ENV RELAYHOST_PASSWORD=

# (optional) Should the postfix relay use TLS
ENV SMTP_USE_TLS=

# Fixes an bug with iconv @see https://github.com/docker-library/php/issues/240
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN apk --no-cache add \
        ca-certificates \
        gettext \
        bash \
        curl \
        rsync \
        sudo \
        git \
        php7 \
        php7-bcmath \
        php7-ctype \
        php7-curl \
        php7-dom \
        php7-fpm \
        php7-fileinfo \
        php7-gd \
        php7-iconv \
        php7-intl \
        php7-json \
        php7-mbstring \
        php7-mcrypt \
        php7-mysqlnd \
        php7-opcache \
        php7-openssl \
        php7-pcntl \
        php7-pecl-lzf \
        php7-pecl-zstd \
        php7-pdo \
        php7-pdo_mysql \
        php7-phar \
        php7-posix \
        php7-redis \
        php7-session \
        php7-simplexml \
        php7-soap \
        php7-sodium \
        php7-sockets \
        php7-tokenizer \
        php7-xml \
        php7-xmlreader \
        php7-xmlwriter \
        php7-xsl \
        php7-zip \
        nginx \
        supervisor \
        postfix \
        unzip \
        && addgroup nginx postdrop && postalias /etc/postfix/aliases && mkdir /var/log/postfix \
        && sed -ie "s#include /etc/nginx/http.d/#include /etc/nginx/conf.d/#g" /etc/nginx/nginx.conf \
        && postconf "smtputf8_enable = no" && postconf "maillog_file=/var/log/postfix/mail.log" \
        && mkdir /var/www/html && chown nginx:nginx /var/www/html \
        && ln -sf /dev/stdout /var/log/nginx/access.log \
        && ln -sf /dev/stderr /var/log/nginx/error.log


COPY conf/www.conf /etc/php7/php-fpm.d/www.conf
COPY conf/default.conf conf/healthz.conf /etc/nginx/conf.d/
COPY healthz /var/www/healthz
COPY bin/setup.sh /setup.sh
COPY bin/run.sh /run.sh
COPY conf/supervisord.conf /etc/supervisord.conf
COPY --from=composer:2.1 /usr/bin/composer /usr/bin/composer

EXPOSE 80

WORKDIR /var/www/html

CMD ["/run.sh"]

