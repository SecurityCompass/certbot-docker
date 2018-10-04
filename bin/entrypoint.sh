#!/bin/sh

echo "Starting 'certbot' entrypoint..."

cert_url="http://${CERT_DOMAIN}"
until curl --output /dev/null --silent --head --fail --connect-timeout 30 "${cert_url}"; do
    echo "Cannot resolve '${cert_url}, sleeping and trying again..."
    sleep 60
done

echo "Successful response from '${cert_url}', attempting to obtain certificate..."
/usr/local/bin/run_certbot.sh -e "${ADMIN_EMAIL}" -d "${CERT_DOMAIN}" -r /challenges
