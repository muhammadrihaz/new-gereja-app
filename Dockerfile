FROM php:8.4-fpm-alpine

RUN apk add --no-cache \
	$PHPIZE_DEPS \
	bash \
	curl \
	icu-dev \
	libzip-dev \
	mysql-client \
	oniguruma-dev \
	unzip \
	zip \
	&& docker-php-ext-install pdo_mysql bcmath intl zip opcache \
	&& pecl install redis \
	&& docker-php-ext-enable redis \
	&& rm -rf /tmp/pear

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

CMD ["php-fpm"]
