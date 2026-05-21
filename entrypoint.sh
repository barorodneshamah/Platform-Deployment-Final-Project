#!/bin/sh
set -e

echo "=== Symfony Application Startup ==="

MAX_TRIES=30
COUNT=0
echo "Waiting for database connection..."

until php bin/console doctrine:query:sql "SELECT 1" > /dev/null 2>&1; do
    COUNT=$((COUNT + 1))
    if [ "$COUNT" -ge "$MAX_TRIES" ]; then
        echo "ERROR: Database not available after ${MAX_TRIES} attempts. Exiting."
        exit 1
    fi
    echo "  Attempt ${COUNT}/${MAX_TRIES} - retrying in 3 seconds..."
    sleep 3
done

echo "Database connection established."

echo "Running database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

echo "Warming up application cache..."
php bin/console cache:clear
php bin/console cache:warmup

chown -R www-data:www-data /var/www/html/var

echo "Starting Nginx..."
nginx

echo "Starting PHP-FPM..."
exec php-fpm -F