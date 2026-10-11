
FROM php:8.2-apache

# Install system packages and required PHP extensions.
RUN apt-get update && apt-get install -y \
        pkg-config \
        libicu-dev \
        libonig-dev \
        libzip-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libwebp-dev \
        unzip \
        git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install intl mbstring mysqli pdo_mysql zip gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Serve CodeIgniter 4 from its public directory.
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf \
    && sed -ri -e "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN a2enmod rewrite headers

# Configure Apache to use prefork MPM with mod_php.
RUN rm -f /etc/apache2/mods-enabled/mpm_event.load \
          /etc/apache2/mods-enabled/mpm_event.conf \
          /etc/apache2/mods-enabled/mpm_worker.load \
          /etc/apache2/mods-enabled/mpm_worker.conf \
    && ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load \
    && ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf

# Allow CodeIgniter's .htaccess rules.
RUN printf '<Directory "%s">\n    AllowOverride All\n</Directory>\n' "$APACHE_DOCUMENT_ROOT" \
    > /etc/apache2/conf-available/z-allow-override.conf \
    && a2enconf z-allow-override

# Install Composer.
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Install dependencies.
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-interaction --optimize-autoloader

# Copy application source.
COPY . .

# Check PHP syntax during the build.
RUN php -l app/Config/Logger.php \
    && php -l app/Config/Database.php \
    && php -l public/index.php

# Ensure writable directories exist and have correct permissions.
RUN mkdir -p writable/logs writable/cache writable/session public/uploads \
    && chown -R www-data:www-data writable public/uploads \
    && chmod -R 775 writable public/uploads

# Copy startup script and remove Windows CRLF characters.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh \
    && chmod 755 /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

# Run the startup script explicitly through the shell.
ENTRYPOINT ["/bin/sh", "/usr/local/bin/docker-entrypoint.sh"]

CMD ["apache2-foreground"]
