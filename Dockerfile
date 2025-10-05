FROM php:8.2-apache

# Dependências para compilar extensões do PHP
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    pkg-config \
    unzip \
    curl \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd mysqli curl mbstring xml zip intl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Use sempre o artefato oficial do GitHub Releases
ARG REVIVE_VERSION=5.4.1
ARG REVIVE_URL=https://github.com/revive-adserver/revive-adserver/releases/download/v${REVIVE_VERSION}/revive-adserver-${REVIVE_VERSION}.zip

# -f: fail on HTTP errors; -S: show errors; -L: follow redirects
RUN curl -fSL "$REVIVE_URL" -o revive.zip \
 && unzip -q revive.zip \
 && mv revive-adserver/* . \
 && rm -rf revive.zip revive-adserver

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
