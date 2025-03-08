#!/bin/bash

# GoDaddy API credentials
API_KEY="3mM44Ywf1966b9_UpXhuVvVYNyjkyF8h1pgMp"
API_SECRET="ALDutmZtMYSHBBtrn5gnNq"

# Function to extract the domain and record name from CERTBOT_DOMAIN
get_domain_and_record() {
    local domain="$1"
    if [[ "$domain" == *"."* ]]; then
        local parts=(${domain//./ })
        local len=${#parts[@]}
        if [[ $len -ge 2 ]]; then
            MAIN_DOMAIN="${parts[$len-2]}.${parts[$len-1]}"
            if [[ $len -gt 2 ]]; then
                RECORD_NAME="${domain%.$MAIN_DOMAIN}"
            else
                RECORD_NAME="@"
            fi
        fi
    fi
}

# Get the domain and record name
get_domain_and_record "$CERTBOT_DOMAIN"

# Create TXT record
create_txt_record() {
    local data="{\"data\":\"$CERTBOT_VALIDATION\",\"ttl\":600}"

    curl -X PUT \
        -H "Authorization: sso-key $API_KEY:$API_SECRET" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "https://api.godaddy.com/v1/domains/$MAIN_DOMAIN/records/TXT/_acme-challenge.$RECORD_NAME"

    # Wait for DNS propagation
    echo "Waiting 30 seconds for DNS propagation..."
    sleep 30
}

# Create the TXT record
create_txt_record

echo "DNS record created successfully"
