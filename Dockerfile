FROM php:8.3-fpm-alpine

# An (optional) host that relays your msgs
ENV RELAYHOST=
# An (optional) username for the relay server
ENV RELAYHOST_USERNAME=
# An (optional) login password for the relay server
ENV RELAYHOST_PASSWORD=

# (optional) Should the postfix relay use TLS
ENV SMTP_USE_TLS=

# List of additional PHP extensions
ENV PHP_EXTENSIONS bcmath gd intl opcache pcntl pdo_mysql soap sockets xsl zip

# Install system dependencies
RUN apk --no-cache add \
        ca-certificates \
        gettext \
        bash \
        curl \
        rsync \
        sudo \
        patch \
        freetype \
        libpng \
        libjpeg-turbo \
        libxslt \
        libzip \
        icu-data-full \
        nginx \
        supervisor \
        postfix \
        unzip

# Install PHP extensions
RUN apk --no-cache add --virtual .build-deps \
     freetype-dev icu-dev zlib-dev libjpeg-turbo-dev libpng-dev libxml2-dev libxslt-dev libzip-dev linux-headers \
    && docker-php-ext-configure \
         gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) $PHP_EXTENSIONS \
    && apk del .build-deps

# Install PECL extensions
RUN apk --no-cache add --virtual .build-deps $PHPIZE_DEPS \
    && pecl install apcu redis lzf zstd \
    && docker-php-ext-enable apcu redis lzf zstd \
    && apk del .build-deps

# Configure nginx and postfix
RUN addgroup nginx postdrop \
    && postalias /etc/postfix/aliases \
    && mkdir /var/log/postfix \
    && sed -i '/Include files with config snippets into the root context/,+1d' /etc/nginx/nginx.conf \
    && sed -ie "s#include /etc/nginx/http.d/#include /etc/nginx/conf.d/#g" /etc/nginx/nginx.conf \
    && postconf "smtputf8_enable = no" && postconf "maillog_file=/var/log/postfix/mail.log" \
    && chown nginx:nginx /var/www/html \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Copy configuration and scripts
COPY conf/www.conf /etc/php82/php-fpm.d/www.conf
COPY conf/default.conf conf/healthz.conf /etc/nginx/conf.d/
COPY healthz /var/www/healthz
COPY bin/setup.sh /setup.sh
COPY bin/run.sh /run.sh
COPY conf/supervisord.conf /etc/supervisord.conf
COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

EXPOSE 80

WORKDIR /var/www/html

CMD ["/run.sh"]
