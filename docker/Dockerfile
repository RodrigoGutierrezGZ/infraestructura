# Multi-stage build para optimizar tamaño de imagen final
FROM php:8.2-fpm-alpine AS base

# Instalar dependencias del sistema
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    git \
    unzip \
    sqlite \
    nodejs \
    npm

# Instalar extensiones PHP necesarias para Laravel
RUN docker-php-ext-install pdo pdo_mysql

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Crear usuario para la aplicación
RUN adduser -D -s /bin/sh laravel
USER laravel

WORKDIR /var/www/html

# ============================================
# Stage 2: Dependencias (cacheable)
# ============================================
FROM base AS dependencies

# Copiar archivos de dependencias primero (mejor cache de Docker)
COPY --chown=laravel:laravel composer.json composer.lock ./

# Instalar dependencias PHP (solo producción)
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Copiar package.json para dependencias Node.js
COPY --chown=laravel:laravel package*.json ./
RUN npm ci --production

# ============================================
# Stage 3: Aplicación (final)
# ============================================
FROM dependencies AS application

# Copiar código fuente
COPY --chown=laravel:laravel . .

# Crear directorios necesarios con permisos correctos
USER root
RUN mkdir -p /var/www/html/storage/logs \
    /var/www/html/storage/framework/cache \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/bootstrap/cache

RUN chown -R laravel:laravel /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Compilar assets
USER laravel
RUN npm run build

# Optimizar Laravel para producción
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# Configurar Nginx
USER root
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf

# Crear base de datos SQLite si no existe
RUN touch /var/www/html/database/database.sqlite
RUN chown laravel:laravel /var/www/html/database/database.sqlite

# Exponer puerto
EXPOSE 80

# Comando de inicio con Supervisor (maneja Nginx + PHP-FPM)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]