#!/bin/sh
set -e

# Define the webroot directory for certbot challenges.
WEBROOT="/var/www/certbot"
mkdir -p "$WEBROOT"

# Attempt initial certificate issuance if CERTBOT_DOMAIN and CERTBOT_EMAIL are provided.
if [ -n "$CERTBOT_DOMAIN" ] && [ -n "$CERTBOT_EMAIL" ]; then
    echo "Attempting to obtain certificate for domain: $CERTBOT_DOMAIN"
    certbot certonly \
        --non-interactive \
        --agree-tos \
        --email "$CERTBOT_EMAIL" \
        --webroot -w "$WEBROOT" \
        -d "$CERTBOT_DOMAIN" || echo "Warning: initial certificate issuance failed."
else
    echo "CERTBOT_DOMAIN and/or CERTBOT_EMAIL not set. Skipping initial certificate issuance."
fi

# Set up a cron job to renew certificates every 12 hours.
# This cron entry runs at minute 0 every 12th hour.
echo "0 */12 * * * certbot renew --quiet && nginx -s reload" >/etc/crontabs/root

# Start the cron daemon in the background.
echo "Starting cron daemon for certificate renewal..."
crond

# Start Nginx in the foreground.
echo "Starting Nginx..."
exec nginx -g 'daemon off;'
