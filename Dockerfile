FROM php:8.2-apache

# Install dependencies
RUN apt-get update && apt-get install -y     libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libxml2-dev libicu-dev unzip curl &&     docker-php-ext-configure gd --with-freetype --with-jpeg &&     docker-php-ext-install gd mysqli curl mbstring xml zip intl

# Workdir
WORKDIR /var/www/html

# Revive version
ARG REVIVE_VERSION=5.4.1

# Download and unpack Revive Adserver
RUN curl -L -o revive.zip https://download.revive-adserver.com/revive-adserver-${REVIVE_VERSION}.zip &&     unzip revive.zip &&     mv revive-adserver/* . &&     rm -rf revive.zip revive-adserver

# Permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
