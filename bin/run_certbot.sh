#!/bin/sh
# shellcheck disable=SC2039,SC2113

set -e

print_usage() {
cat << EOF
usage: ${0} options

This script wraps certbot to obtain and renew certificates.

OPTIONS:
    Parameters:
    -d Domain for certificate.
    -e Administrator email used when obtaining certificates.
    -r Webroot location to place challenge auth files.

Version: ${VERSION}
EOF
}

function check_for_cert {
    # Check if certificate directory exists
    if [ -z "${1}" ] ; then
        echo "Missing parameter 1: Domain name"
        return 1
    fi

    local cert_domain="${1}"
    local cert_dir="/etc/letsencrypt/live/${cert_domain}"

    [ -d "${cert_dir}" ] && return 0 || return 1
}

function copy_certificates {
    # Copy certificate files to /certs/ docker volume
    # Check if certificate directory exists
    if [ -z "${1}" ] ; then
        echo "Missing parameter 1: Domain name"
        return 1
    fi

    local cert_domain="${1}"

    cp -v /etc/letsencrypt/live/"${cert_domain}"/cert.pem /certs/"${cert_domain}".pem
    cp -v /etc/letsencrypt/live/"${cert_domain}"/privkey.pem /certs/"${cert_domain}".key.pem
    cp -v /etc/letsencrypt/live/"${cert_domain}"/chain.pem /certs/"${cert_domain}".chain.pem
    cp -v /etc/letsencrypt/live/"${cert_domain}"/fullchain.pem /certs/"${cert_domain}".fullchain.pem
}

function obtain_certificate {
    # Obtain certificate for provided domain
    if [ -z "${1}" ] ; then
        echo "Missing parameter 1: Admin email"
        return 1
    fi
    if [ -z "${2}" ] ; then
        echo "Missing parameter 2: Certificate domain name"
        return 1
    fi
    if [ -z "${3}" ] ; then
        echo "Missing parameter 3: Webroot location"
        return 1
    fi

    local admin_email="${1}"
    local certificate_domain="${2}"
    local certificate_webroot="${3}"

    echo "Obtaining certificate for ${certificate_domain}"

    certbot certonly \
        --webroot -w "${certificate_webroot}" \
        --keep-until-expiring \
        --agree-tos \
        --renew-by-default \
        --non-interactive \
        --max-log-backups 100 \
        --email "${admin_email}" \
        --domain "${certificate_domain}"
}

function renew_certificate {
    echo "Renewing certificates registered on system."
    certbot renew \
        --webroot -w "${cert_webroot}" \
        --non-interactive \
        --deploy-hook copy_certificates.sh
}

function process_certificates {
    # Check certificate for expiry, renew if required and move to correct location.
    if [ -z "${1}" ] ; then
        echo "Missing parameter 1: Admin email"
        return 1
    fi

    if [ -z "${2}" ] ; then
        echo "Missing parameter 2: Certificate domain name"
        return 1
    fi
    if [ -z "${3}" ] ; then
        echo "Missing parameter 3: Webroot location"
        return 1
    fi

    local admin_email="${1}"
    local cert_domain="${2}"
    local cert_webroot="${3}"

    if check_for_cert "${cert_domain}"; then
        renew_certificate "${admin_email}" "${cert_domain}" "${cert_webroot}"
    else
        obtain_certificate "${admin_email}" "${cert_domain}" "${cert_webroot}"
    fi

    copy_certificates "${cert_domain}"
}

admin_email="${admin_email:-}"
certificate_domain="${certificate_domain:-}"
certificate_webroot="${certificate_webroot:-}"
while getopts ":d:e:r:A:SD" opt; do
    case ${opt} in
        'd') certificate_domain="${OPTARG}" ;;
        'r') certificate_webroot="${OPTARG}" ;;
        'e') admin_email="${OPTARG}" ;;
        '?')
            echo "Invalid option: -${OPTARG}"
            print_usage
            exit 0
        ;;
        ':')
            echo "Missing option argument for -${OPTARG}"
            print_usage
            exit 0
        ;;
        '*')    # Anything else
            echo "Unknown error while processing options"
            print_usage
            exit 1
        ;;
    esac
done

process_certificates "${admin_email}" "${certificate_domain}" "${certificate_webroot}"
