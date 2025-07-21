FROM php:8.3-fpm

ENV PS1="\u@\h:\w\$ "
ENV TZ="Asia/Jakarta"
ENV COMPOSER_MEMORY_LIMIT='-1'

RUN apt-get update &&     apt-get install -y --no-install-recommends         libmemcached-dev         iputils-ping         telnet         netcat-openbsd         net-tools         libmcrypt-dev         libreadline-dev         libgmp-dev         libzip-dev         libz-dev         libpq-dev         libjpeg-dev         libpng-dev         libfreetype6-dev         libssl-dev         openssh-server         libmagickwand-dev         git         cron         nano         libxml2-dev         nodejs         npm     && rm -r /var/lib/apt/lists/*

RUN docker-php-ext-install soap exif pcntl intl gmp zip pdo_mysql pdo_pgsql bcmath

RUN pecl install redis && docker-php-ext-enable redis
RUN pecl install mongodb && docker-php-ext-enable mongodb
RUN pecl install imagick && docker-php-ext-enable imagick
RUN pecl install xdebug
RUN pecl install memcached && docker-php-ext-enable memcached

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp &&     docker-php-ext-install gd

RUN curl -s http://getcomposer.org/installer | php &&     mv composer.phar /usr/local/bin/composer &&     echo "export PATH=\$PATH:/var/www/html/vendor/bin" >> ~/.bashrc

RUN echo "* * * * * root /usr/local/bin/php /var/www/html/artisan schedule:run >> /dev/null 2>&1" > /etc/cron.d/laravel-scheduler &&     chmod 0644 /etc/cron.d/laravel-scheduler

ADD ./local.ini /usr/local/etc/php/conf.d

RUN echo '#!/bin/bash\nphp /var/www/html/artisan "$@"' > /usr/bin/art && chmod +x /usr/bin/art
RUN echo '#!/bin/bash\nphp /var/www/html/artisan migrate "$@"' > /usr/bin/migrate && chmod +x /usr/bin/migrate
RUN echo '#!/bin/bash\nphp /var/www/html/artisan migrate:fresh --seed' > /usr/bin/fresh && chmod +x /usr/bin/fresh
RUN echo '#!/bin/bash\nphp /var/www/html/artisan config:clear\nvendor/bin/phpunit -d memory_limit=2G --stop-on-error --stop-on-failure --testdox-text=tests/report.txt "$@"' > /usr/bin/t && chmod +x /usr/bin/t
RUN echo '#!/bin/bash\nphp /var/www/html/artisan config:clear\nphp /var/www/html/artisan dusk -d memory_limit=2G --stop-on-error --stop-on-failure --testdox-text=tests/report-dusk.txt "$@"' > /usr/bin/d && chmod +x /usr/bin/d

WORKDIR /var/www/html

COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && ln -s /usr/local/bin/docker-entrypoint.sh /

ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 9000
CMD ["php-fpm"]
