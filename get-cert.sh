#!/bin/sh
. /opt/certbot-venv/bin/activate
certbot certonly --authenticator dns-godaddy \
  --dns-godaddy-credentials /etc/letsencrypt/credentials.ini \
  -d braisenly.com -d *.braisenly.com \
  -d lukezautke.com -d *.lukezautke.com \
  --email luke@braisenly.com --agree-tos --no-eff-email \
  --force-renewal
