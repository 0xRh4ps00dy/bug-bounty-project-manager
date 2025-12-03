FROM php:8.2-apache

# Instal·lar extensions de PHP necessàries
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Habilitar mod_rewrite d'Apache
RUN a2enmod rewrite

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
