FROM php:8.2-fpm
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip libzip-dev netcat-openbsd
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
# Set working directory
WORKDIR /var/www
# Copy code as root first
COPY . .
RUN mkdir -p storage bootstrap/cache && chmod -R 775 storage bootstrap/cache
# Fix git safe directory using --system
RUN git config --system --add safe.directory /var/www
# Install Composer deps
RUN composer install --no-dev --no-interaction --optimize-autoloader --no-scripts
RUN composer dump-autoload --optimize
RUN chown -R 33:33 /var/www
RUN chown -R 33:33 /var/www
RUN chown -R 33:33 /var/www
# Set permissions
# Switch to www-data after everything
USER 33
CMD ["php-fpm"]
