FROM php:fpm
LABEL Description="php-fpm + nginx + composer" Vendor="ivanets" Version="1.0" maintainer="evgeniyivanets@gmail.com"
EXPOSE 80 443
WORKDIR /app
RUN apt-get update \
    && apt-get -y install libicu52 libicu-dev git vim zlib1g-dev --no-install-recommends \
    && apt-get -yqq install ssh \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-install -j$(nproc) opcache \
    && pecl install apcu-5.1.8 && docker-php-ext-enable apcu \
    && docker-php-ext-install -j$(nproc) zip \
    && docker-php-ext-install -j$(nproc) mysqli \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && apt-get purge -y icu-devtools libicu-dev zlib1g-dev \
    && apt-get autoremove -y \
    && rm -r /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y nginx \
    && echo "daemon off;" >> /etc/nginx/nginx.conf
RUN mkdir /root/.composer/
RUN mkdir /root/.ssh/
# Bitbucket key to READ repositories for composer
ARG BITBUCKET_KEY=./keys/remote_access
COPY ${BITBUCKET_KEY} /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts && ssh-keyscan "bitbucket.org" >> /root/.ssh/known_hosts
# Github token to READ repositories for composer
RUN echo '{"github-oauth": {"github.com": "d8a6f5d51e25ac5fd21775f5c261ca1295c0d788"}}' > /root/.composer/auth.json
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/bin --filename=composer \
    && rm composer-setup.php
# TODO: In case of ugly logs
# https://github.com/docker-library/php/issues/207
# https://bugs.php.net/bug.php?id=71880
RUN set -ex \
    && { \
    echo '[global]'; \
    echo 'error_log = /proc/self/fd/2'; \
    echo 'daemonize = yes'; \
    echo; \
    echo '[www]'; \
    echo 'listen = [::]:9000'; \
    echo 'access.log = /proc/self/fd/2'; \
    } | tee /usr/local/etc/php-fpm.d/zz-docker.conf
RUN mkdir -p noserver/web && echo "<h1>NoServer</h1>" > noserver/web/index.html \
    && mkdir -p default/web && echo "<?php phpinfo();?>" > default/web/index.php
COPY ./nginx/default.nginx.conf /etc/nginx/sites-enabled/default
CMD php-fpm && nginx
