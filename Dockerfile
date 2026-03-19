FROM wordpress:php8.3-apache

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    less \
    mariadb-client \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && curl -fsSLO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar.sha512 \
    && test "$(cat wp-cli.phar.sha512)" = "$(sha512sum wp-cli.phar | awk '{print $1}')" \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && rm -f wp-cli.phar.sha512
