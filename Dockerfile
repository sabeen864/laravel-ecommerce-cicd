FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip libzip-dev

RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

COPY --chown=33:33 . .

USER 33

# Fix git safe directory
RUN git config --global --add safe.directory /var/www

RUN composer install --no-dev --no-interaction --optimize-autoloader --no-scripts
RUN composer dump-autoload --optimize

RUN chmod -R 775 storage bootstrap/cache && chmod 755 artisan

CMD ["php-fpm"]
