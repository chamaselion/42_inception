#!/bin/bash
set -e

cd /var/www/html || exit 1

WP_PHP_PORT="${WP_PHP_PORT:-9000}"
MARIADB_PORT="${MARIADB_PORT:-3306}"
NGINX_PORT="${NGINX_PORT:-443}"

if [ "$NGINX_PORT" = "443" ]; then
  WP_URL="https://$DOMAIN_NAME"
else
  WP_URL="https://$DOMAIN_NAME:$NGINX_PORT"
fi

# find PHP pool config and php.ini
WWW_CONF=""
for f in /etc/php/*/fpm/pool.d/www.conf /etc/php/*/php-fpm.d/www.conf; do
  [ -f "$f" ] && { WWW_CONF="$f"; break; }
done

PHP_INI=""
for i in /etc/php/*/fpm/php.ini /etc/php/*/php.ini; do
  [ -f "$i" ] && { PHP_INI="$i"; break; }
done

# find php-fpm binary
PHP_FPM_BIN=""
for b in /usr/sbin/php-fpm* /usr/bin/php-fpm*; do
  [ -x "$b" ] && { PHP_FPM_BIN="$b"; break; }
done
command -v php-fpm >/dev/null 2>&1 && PHP_FPM_BIN="${PHP_FPM_BIN:-$(command -v php-fpm)}"

if [ ! -e /etc/.firstrun ]; then
  if [ -n "$WWW_CONF" ]; then
    sed -i -E "s@^listen\s*=.*@listen = ${WP_PHP_PORT}@" "$WWW_CONF" || true
    sed -i -E 's@^user\s*=.*@user = nginx@' "$WWW_CONF" || true
    sed -i -E 's@^group\s*=.*@group = nginx@' "$WWW_CONF" || true
  fi

  if [ -n "$PHP_INI" ]; then
    grep -q '^memory_limit' "$PHP_INI" >/dev/null 2>&1 || echo "memory_limit = 256M" >> "$PHP_INI"
  fi

  touch /etc/.firstrun
fi

DB_WAIT_TIMEOUT="${DB_WAIT_TIMEOUT:-60}"
DB_READY=0

for _ in $(seq 1 "$DB_WAIT_TIMEOUT"); do
  if mysql --protocol=tcp --host=mariadb --port="$MARIADB_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
    DB_READY=1
    break
  fi
  sleep 1
done

if [ "$DB_READY" -ne 1 ]; then
  echo "Error: MariaDB user/database not ready within ${DB_WAIT_TIMEOUT}s" >&2
  exit 1
fi

if [ ! -f wp-includes/version.php ]; then
  wp core download --allow-root --force --path=/var/www/html
fi

if [ ! -f wp-config.php ]; then
  wp config create --allow-root --dbhost="mariadb:$MARIADB_PORT" --dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" --dbname="$MYSQL_DATABASE" --path=/var/www/html --force
else
  sed -i "s/define( 'DB_NAME', '.*' );/define( 'DB_NAME', '$MYSQL_DATABASE' );/" wp-config.php
  sed -i "s/define( 'DB_USER', '.*' );/define( 'DB_USER', '$MYSQL_USER' );/" wp-config.php
  sed -i "s/define( 'DB_PASSWORD', '.*' );/define( 'DB_PASSWORD', '$MYSQL_PASSWORD' );/" wp-config.php
  sed -i "s/define( 'DB_HOST', '.*' );/define( 'DB_HOST', 'mariadb:$MARIADB_PORT' );/" wp-config.php
fi

if ! wp core is-installed --allow-root --path=/var/www/html >/dev/null 2>&1; then
  wp core install --allow-root --skip-email --url="$WP_URL" --title="$WORDPRESS_TITLE" --admin_user="$WORDPRESS_ADMIN_USER" --admin_password="$WORDPRESS_ADMIN_PASSWORD" --admin_email="$WORDPRESS_ADMIN_EMAIL" --path=/var/www/html
fi

wp option update home "$WP_URL" --allow-root --path=/var/www/html >/dev/null
wp option update siteurl "$WP_URL" --allow-root --path=/var/www/html >/dev/null

if wp user get "$WORDPRESS_ADMIN_USER" --allow-root --path=/var/www/html >/dev/null 2>&1; then
  wp user update "$WORDPRESS_ADMIN_USER" --user_pass="$WORDPRESS_ADMIN_PASSWORD" --user_email="$WORDPRESS_ADMIN_EMAIL" --allow-root --path=/var/www/html >/dev/null
else
  wp user create "$WORDPRESS_ADMIN_USER" "$WORDPRESS_ADMIN_EMAIL" --role=administrator --user_pass="$WORDPRESS_ADMIN_PASSWORD" --allow-root --path=/var/www/html >/dev/null
fi

SECOND_USER="$WORDPRESS_USER"
if [ "$SECOND_USER" = "$WORDPRESS_ADMIN_USER" ]; then
  SECOND_USER="${WORDPRESS_USER}_author"
fi

if wp user get "$SECOND_USER" --allow-root --path=/var/www/html >/dev/null 2>&1; then
  wp user update "$SECOND_USER" --user_pass="$WORDPRESS_PASSWORD" --user_email="$WORDPRESS_EMAIL" --role=author --allow-root --path=/var/www/html >/dev/null
else
  wp user create "$SECOND_USER" "$WORDPRESS_EMAIL" --role=author --user_pass="$WORDPRESS_PASSWORD" --allow-root --path=/var/www/html >/dev/null
fi

touch .firstmount

chown -R nginx:nginx /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

if [ -n "$PHP_FPM_BIN" ]; then
  exec "$PHP_FPM_BIN" -F
else
  exec php-fpm -F
fi