FROM php:8.3-fpm

RUN apt-get update && apt-get install -y \
    nginx \
    libicu-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    git \
    && docker-php-ext-configure intl \
    && docker-php-ext-install pdo pdo_mysql intl zip opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.validate_timestamps=0'; \
    echo 'opcache.revalidate_freq=0'; \
} > /usr/local/etc/php/conf.d/opcache.ini

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html


COPY composer.json composer.lock symfony.lock importmap.php ./


RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-scripts \
    --no-interaction \
    --prefer-dist

COPY . .

RUN APP_ENV=prod APP_SECRET=build-placeholder \
        php bin/console assets:install --no-debug \
    && APP_ENV=prod APP_SECRET=build-placeholder \
        php bin/console importmap:install --no-debug \
    && APP_ENV=prod APP_SECRET=build-placeholder \
        php bin/console cache:clear --no-debug

RUN chown -R www-data:www-data var \
    && chmod -R 775 var

COPY nginx-main.conf /etc/nginx/nginx.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]