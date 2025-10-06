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

# Configuração para proxy HTTPS
RUN printf "ServerName localhost\n\
<IfModule mod_setenvif.c>\n\
    SetEnvIf X-Forwarded-Proto https HTTPS=on\n\
    SetEnvIf X-Forwarded-Proto https HTTPS=1\n\
</IfModule>\n" > /etc/apache2/conf-available/proxy-https.conf \
 && a2enconf proxy-https

# Instala PEAR e bibliotecas HTML necessárias
RUN curl -sS https://pear.php.net/go-pear.phar -o go-pear.phar \
 && php go-pear.phar -d php_dir=/usr/local/lib/php -d data_dir=/usr/local/lib/php/data -d test_dir=/usr/local/lib/php/tests -d doc_dir=/usr/local/lib/php/docs \
 && rm go-pear.phar \
 && pear channel-update pear.php.net \
 && pear install --alldeps HTML_Common \
 && pear install --alldeps HTML_QuickForm

WORKDIR /var/www/html

# Baixa o pacote de release oficial - versão 5.5.2
ARG REVIVE_VERSION=5.5.2
ARG REVIVE_URL=https://download.revive-adserver.com/revive-adserver-${REVIVE_VERSION}.tar.gz

RUN curl -fSL -A "Mozilla/5.0" "$REVIVE_URL" -o revive.tar.gz \
 && tar -xzf revive.tar.gz \
 && mv revive-adserver-${REVIVE_VERSION}/* . \
 && rm -rf revive.tar.gz revive-adserver-${REVIVE_VERSION}

# Força detecção de HTTPS e define constantes necessárias
RUN echo "<?php" > /var/www/html/init.php \
 && echo "if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {" >> /var/www/html/init.php \
 && echo "    \$_SERVER['HTTPS'] = 'on';" >> /var/www/html/init.php \
 && echo "    \$_SERVER['SERVER_PORT'] = 443;" >> /var/www/html/init.php \
 && echo "}" >> /var/www/html/init.php \
 && echo "define('MAX_PATH', dirname(__FILE__));" >> /var/www/html/init.php \
 && echo "define('LIB_PATH', MAX_PATH . '/lib');" >> /var/www/html/init.php \
 && echo "define('RV_PATH', MAX_PATH);" >> /var/www/html/init.php \
 && echo "define('OX_PATH', MAX_PATH);" >> /var/www/html/init.php \
 && echo "?>" >> /var/www/html/init.php

# Configura PHP para carregar init.php antes de qualquer script
RUN echo "auto_prepend_file = /var/www/html/init.php" >> /usr/local/etc/php/conf.d/revive.ini

# Permissões
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80