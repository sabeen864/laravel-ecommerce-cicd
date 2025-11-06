FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip libzip-dev

RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy code as root first
COPY . .

# Fix git safe directory using --system
RUN git config --system --add safe.directory /var/www

# Install Composer deps
RUN composer install --no-dev --no-interaction --optimize-autoloader --no-scripts
RUN composer dump-autoload --optimize

# Set permissions
RUN chmod -R 775 storage bootstrap/cache && chmod 755 artisan

# Switch to www-data after everything
USER 33

CMD ["php-fpm"]
