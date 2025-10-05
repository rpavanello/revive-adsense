FROM php:8.2-apache

# Pacotes necessários para compilar as extensões do PHP (inclui libcurl e pkg-config)
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    pkg-config \
    unzip \
    curl \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd mysqli curl mbstring xml zip intl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

ARG REVIVE_VERSION=5.4.1
RUN curl -L -o revive.zip https://download.revive-adserver.com/revive-adserver-${REVIVE_VERSION}.zip \
 && unzip revive.zip \
 && mv revive-adserver/* . \
 && rm -rf revive.zip revive-adserver

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80