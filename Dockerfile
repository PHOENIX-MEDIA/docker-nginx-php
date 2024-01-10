FROM alpine:3.18

# An (optional) host that relays your msgs
ENV RELAYHOST=
# An (optional) username for the relay server
ENV RELAYHOST_USERNAME=
# An (optional) login password for the relay server
ENV RELAYHOST_PASSWORD=

# (optional) Should the postfix relay use TLS
ENV SMTP_USE_TLS=

RUN apk --no-cache add \
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
        php81 \
        php81-bcmath \
        php81-ctype \
        php81-curl \
        php81-dom \
        php81-fpm \
        php81-fileinfo \
        php81-gd \
        php81-iconv \
        php81-intl \
        php81-json \
        php81-mbstring \
        php81-common \
        php81-mysqlnd \
        php81-opcache \
        php81-openssl \
        php81-pcntl \
        php81-pecl-apcu \
        php81-pecl-lzf \
        php81-pecl-zstd \
        php81-pdo \
        php81-pdo_mysql \
        php81-phar \
        php81-posix \
        php81-redis \
        php81-session \
        php81-simplexml \
        php81-soap \
        php81-sodium \
        php81-sockets \
        php81-tokenizer \
        php81-xml \
        php81-xmlreader \
        php81-xmlwriter \
        php81-xsl \
        php81-zip \
        && addgroup nginx postdrop && postalias /etc/postfix/aliases && mkdir /var/log/postfix \
        && sed -i '/Include files with config snippets into the root context/,+1d' /etc/nginx/nginx.conf \
        && sed -ie "s#include /etc/nginx/http.d/#include /etc/nginx/conf.d/#g" /etc/nginx/nginx.conf \
        && postconf "smtputf8_enable = no" && postconf "maillog_file=/var/log/postfix/mail.log" \
        && mkdir /var/www/html && chown nginx:nginx /var/www/html \
        && ln -sf /dev/stdout /var/log/nginx/access.log \
        && ln -sf /dev/stderr /var/log/nginx/error.log

# workaround for iconv issue
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv==1.15-r3
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

COPY conf/www.conf /etc/php81/php-fpm.d/www.conf
COPY conf/default.conf conf/healthz.conf /etc/nginx/conf.d/
COPY healthz /var/www/healthz
COPY bin/setup.sh /setup.sh
COPY bin/run.sh /run.sh
COPY conf/supervisord.conf /etc/supervisord.conf
COPY --from=composer:2.1 /usr/bin/composer /usr/bin/composer

EXPOSE 80

WORKDIR /var/www/html

CMD ["/run.sh"]

