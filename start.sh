#!/bin/sh
#set -e

# Define the webroot directory for certbot challenges.
WEBROOT="/var/www/certbot"
mkdir -p "$WEBROOT"

# Attempt initial certificate issuance if CERTBOT_DOMAINS and CERTBOT_EMAIL are provided.
if [ -n "$CERTBOT_DOMAINS" ] && [ -n "$CERTBOT_EMAIL" ]; then
    echo "Attempting to obtain certificate for domains: $CERTBOT_DOMAINS"
    # Convert space-separated domains into -d arguments
    DOMAIN_ARGS=""
    for domain in $CERTBOT_DOMAINS; do
        DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
    done

    certbot certonly \
        --non-interactive \
        --agree-tos \
        --email "$CERTBOT_EMAIL" \
        --webroot -w "$WEBROOT" \
        $DOMAIN_ARGS || echo "Warning: initial certificate issuance failed."
else
    echo "CERTBOT_DOMAINS and/or CERTBOT_EMAIL not set. Skipping initial certificate issuance."
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
