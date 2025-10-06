FROM php:8.2-apache

# Pacotes para compilar extensões + ferramentas do composer
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
    git \
    curl \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd mysqli curl mbstring xml zip intl \
 && a2enmod rewrite headers expires setenvif \
 && rm -rf /var/lib/apt/lists/*

# Configuração para proxy HTTPS - ADICIONAR AQUI
RUN printf "ServerName localhost\n\
<IfModule mod_setenvif.c>\n\
    SetEnvIf X-Forwarded-Proto https HTTPS=on\n\
    SetEnvIf X-Forwarded-Proto https HTTPS=1\n\
</IfModule>\n" > /etc/apache2/conf-available/proxy-https.conf \
 && a2enconf proxy-https

# Composer (oficial)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/html

# Baixa o código da tag (não contém vendor)
ARG REVIVE_VERSION=5.4.1
ARG REVIVE_URL=https://github.com/revive-adserver/revive-adserver/archive/refs/tags/v${REVIVE_VERSION}.zip

RUN curl -fSL "$REVIVE_URL" -o revive.zip \
 && unzip -q revive.zip \
 && mv revive-adserver-${REVIVE_VERSION}/* . \
 && rm -rf revive.zip revive-adserver-${REVIVE_VERSION}

# Instala as dependências PHP do projeto (gera lib/vendor)
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --no-interaction --prefer-dist --no-progress

# Permissões
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80