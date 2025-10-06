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

# Instala PEAR e bibliotecas HTML
RUN curl -sS https://pear.php.net/go-pear.phar -o go-pear.phar \
 && php go-pear.phar -d php_dir=/usr/local/lib/php \
 && rm go-pear.phar \
 && pear install --alldeps HTML_Common HTML_QuickForm

WORKDIR /var/www/html

# Download do Dropbox
RUN curl -L -o revive-adserver-5.5.2.tar.gz "https://www.dropbox.com/scl/fi/l6khvi9qs16eh1icfkrkh/revive-adserver-5.5.2.tar.gz?rlkey=1bwvyo4gpx6abi1pls2yxj26e&dl=1" \
 && tar -xzf revive-adserver-5.5.2.tar.gz \
 && mv revive-adserver-5.5.2/* . \
 && rm -rf revive-adserver-5.5.2.tar.gz revive-adserver-5.5.2

# Cria os arquivos que estão faltando no pacote
RUN mkdir -p /var/www/html/lib/Plugin \
 && echo "<?php\nclass PluginManager {}\n?>" > /var/www/html/lib/Plugin/PluginManager.php

RUN mkdir -p /var/www/html/lib/Admin \
 && echo "<?php\nclass OA_Admin_Redirect {}\n?>" > /var/www/html/lib/Admin/Redirect.php

# Força detecção HTTPS e define constantes
RUN echo "<?php\nif (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {\n    \$_SERVER['HTTPS'] = 'on'; \$_SERVER['SERVER_PORT'] = 443;\n}\ndefine('MAX_PATH', __DIR__);\ndefine('LIB_PATH', MAX_PATH . '/lib');\ndefine('RV_PATH', MAX_PATH);\ndefine('OX_PATH', MAX_PATH);" > init.php

RUN echo "auto_prepend_file = /var/www/html/init.php" >> /usr/local/etc/php/conf.d/revive.ini

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80