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

# Delete TXT record
delete_txt_record() {
    curl -X DELETE \
        -H "Authorization: sso-key $API_KEY:$API_SECRET" \
        "https://api.godaddy.com/v1/domains/$MAIN_DOMAIN/records/TXT/_acme-challenge.$RECORD_NAME"
}

# Delete the TXT record
delete_txt_record

echo "DNS record deleted successfully"
