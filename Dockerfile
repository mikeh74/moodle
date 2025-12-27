# Dockerfile for Moodle with PHP and Apache

# Builder stage: compile PHP extensions
FROM php:8.2-apache AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libonig-dev \
    libicu-dev \
    libxslt1-dev \
    libpq-dev \
    libldap2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd zip xml intl mbstring xsl soap pdo pdo_mysql mysqli opcache exif pcntl \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /tmp/pear /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Base stage: runtime environment with minimal dependencies
FROM php:8.2-apache AS base

# Copy compiled PHP extensions from builder
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Install only runtime libraries (not -dev packages)
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    libpng16-16 \
    libjpeg62-turbo \
    libfreetype6 \
    libzip-dev \
    libxml2 \
    libonig-dev \
    libicu-dev \
    libxslt1-dev \
    cron \
    ghostscript \
    libpq5 \
    libldap2 \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN a2enmod rewrite
WORKDIR /var/www/html

# Copy configuration files
COPY moodle-php.ini /usr/local/etc/php/conf.d/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]

# Development stage
FROM base AS development

# RUN apt-get update && apt-get install -y --no-install-recommends nano vim && apt-get clean && rm -rf /var/lib/apt/lists/*
CMD ["apache2-foreground"]

# Production stage
FROM base AS production

# Copy application code (placed last for better layer caching)
COPY . /var/www/html
CMD ["apache2-foreground"]
