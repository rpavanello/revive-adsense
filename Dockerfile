FROM php:8.2-apache

# Pacotes necessários
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    libxml2-dev libicu-dev libcurl4-openssl-dev libonig-dev \
    pkg-config unzip git curl \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd mysqli curl mbstring xml zip intl \
 && a2enmod rewrite headers expires setenvif \
 && rm -rf /var/lib/apt/lists/*

# Configuração proxy HTTPS
RUN printf "ServerName localhost\n\
<IfModule mod_setenvif.c>\n\
    SetEnvIf X-Forwarded-Proto https HTTPS=on\n\
    SetEnvIf X-Forwarded-Proto https HTTPS=1\n\
</IfModule>\n" > /etc/apache2/conf-available/proxy-https.conf \
 && a2enconf proxy-https

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/html

# Clona o código-fonte do GitHub (branch v5.5.2)
RUN git clone --depth 1 --branch v5.5.2 https://github.com/revive-adserver/revive-adserver.git . \
 && composer install --no-dev --no-interaction --optimize-autoloader

# PEAR para bibliotecas antigas
RUN curl -sS https://pear.php.net/go-pear.phar -o go-pear.phar \
 && php go-pear.phar -d php_dir=/usr/local/lib/php \
 && rm go-pear.phar \
 && pear install --alldeps HTML_Common HTML_QuickForm

# Força HTTPS e constantes
RUN echo "<?php" > init.php \
 && echo "if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {" >> init.php \
 && echo "    \$_SERVER['HTTPS'] = 'on'; \$_SERVER['SERVER_PORT'] = 443;" >> init.php \
 && echo "}" >> init.php \
 && echo "define('MAX_PATH', __DIR__);" >> init.php \
 && echo "define('LIB_PATH', MAX_PATH . '/lib');" >> init.php \
 && echo "define('RV_PATH', MAX_PATH);" >> init.php \
 && echo "define('OX_PATH', MAX_PATH);" >> init.php

RUN echo "auto_prepend_file = /var/www/html/init.php" >> /usr/local/etc/php/conf.d/revive.ini

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80