#!/bin/bash
set -e

# Ensure moodledata exists and is owned by www-data
if [ ! -d /var/www/moodledata ]; then
    mkdir -p /var/www/moodledata
fi
chown -R www-data:www-data /var/www/moodledata

exec "$@"
