#!/usr/bin/env bash
set -e

# Define the webroot directory for certbot challenges - match this with Nginx config
WEBROOT="/var/www/html"
mkdir -p "$WEBROOT"

# Ensure Nginx is running to accept the challenge
echo "Starting Nginx temporarily to handle ACME challenges..."
nginx -g 'daemon off;' &
NGINX_PID=$!

# Give Nginx time to start
sleep 5

# Check if port 80 is accessible
echo "Testing HTTP connectivity..."
curl -s -o /dev/null -w "%{http_code}\n" http://localhost/.well-known/acme-challenge/test || {
  echo "Warning: HTTP server isn't responding on localhost. Check Nginx configuration."
}

# Attempt initial certificate issuance if CERTBOT_DOMAINS and CERTBOT_EMAIL are provided
if [ -n "$CERTBOT_DOMAINS" ] && [ -n "$CERTBOT_EMAIL" ]; then
    echo "Attempting to obtain certificate for domains: $CERTBOT_DOMAINS"
    
    # Convert space-separated domains into -d arguments
    DOMAIN_ARGS=""
    for domain in $CERTBOT_DOMAINS; do
        DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
    done
    
    # Run certbot with more verbose output
    certbot certonly \
        --non-interactive \
        --agree-tos \
        --email "$CERTBOT_EMAIL" \
        --webroot -w "$WEBROOT" \
        --preferred-challenges http \
        -v \
        $DOMAIN_ARGS || echo "Warning: initial certificate issuance failed. Check network and DNS settings."
else
    echo "CERTBOT_DOMAINS and/or CERTBOT_EMAIL not set. Skipping initial certificate issuance."
fi

# Stop the temporary Nginx
if [ -n "$NGINX_PID" ]; then
  echo "Stopping temporary Nginx instance..."
  kill $NGINX_PID
  wait $NGINX_PID 2>/dev/null || true
fi

# Set up a cron job to renew certificates every 12 hours
echo "0 */12 * * * certbot renew --quiet && nginx -s reload" > /etc/crontabs/root

# Start the cron daemon in the background
echo "Starting cron daemon for certificate renewal..."
crond

# Start Nginx in the foreground 
echo "Starting Nginx with SSL configuration..."
exec nginx -g 'daemon off;'
