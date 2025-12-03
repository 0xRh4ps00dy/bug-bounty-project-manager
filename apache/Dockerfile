FROM php:8.2-apache

# Instal·lar extensions de PHP necessàries
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Instal·lar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instal·lar dependències del sistema
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Habilitar mod_rewrite d'Apache
RUN a2enmod rewrite

# Configurar Apache DocumentRoot per apuntar a /var/www/html/public
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/apache2.conf

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html

# Copiar fitxers de l'aplicació
WORKDIR /var/www/html

# Instal·lar dependències de Composer al iniciar
CMD composer install --no-dev --optimize-autoloader && apache2-foreground

EXPOSE 80
