FROM php:8.2-fpm
RUN apt-get update && apt-get install -y git curl libpng-dev libonig-dev libxml2-dev zip unzip libzip-dev netcat-openbsd && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
WORKDIR /var/www
COPY composer.* ./
RUN composer install --no-dev --no-scripts --optimize-autoloader --no-interaction
COPY . .
RUN composer dump-autoload --optimize
RUN mkdir -p storage/framework/{sessions,views,cache} storage/logs bootstrap/cache \
    && touch storage/logs/laravel.log \
    && chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage \
    && chmod -R 775 /var/www/bootstrap/cache
USER www-data
CMD ["php-fpm"]
