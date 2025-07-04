# Dockerfile for Moodle with PHP and Apache

# Base stage: install all dependencies
FROM php:8.2-apache AS base

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libzip-dev \
        libxml2-dev \
        libonig-dev \
        libicu-dev \
        libmcrypt-dev \
        libxslt1-dev \
        git \
        unzip \
        cron \
        ghostscript \
        graphviz \
        aspell \
        clamav \
        clamav-daemon \
        libpq-dev \
        libldap2-dev \
        libmemcached-dev \
        libmagickwand-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd zip xml intl mbstring xsl soap pdo pdo_mysql mysqli opcache exif pcntl \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite
WORKDIR /var/www/html

# Development stage
FROM base AS development

RUN apt-get update && apt-get install -y nano vim && rm -rf /var/lib/apt/lists/*

# Ensure moodledata directory exists and is writeable by www-data
# RUN mkdir -p /var/www/moodledata \
#     && chown -R www-data:www-data /var/www/moodledata

# For development, mount source code from host
# COPY . /var/www/html

COPY moodle-php.ini /usr/local/etc/php/conf.d/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]

# Production stage
FROM base AS production

COPY . /var/www/html
COPY moodle-php.ini /usr/local/etc/php/conf.d/

EXPOSE 80
CMD ["apache2-foreground"]
