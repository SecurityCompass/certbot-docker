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
    if [ -z "${1}" ] ; then
        echo "Missing parameter 1: Domain name"
        return 1
    fi
    local cert_domain="${1}"

    local cert_dir="/etc/letsencrypt/live/${cert_domain}"

    echo "Check if certificate directory exists"
    [ -d "${cert_dir}" ] && return 0 || return 1
}

function copy_certificates {
    if [ -z "${1}" ] ; then
        echo "Missing parameter 1: Domain name"
        return 1
    fi
    local cert_domain="${1}"

    echo "Copy certificate files to /certs/ docker volume"
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
    local admin_email="${1}"

    if [ -z "${2}" ] ; then
        echo "Missing parameter 2: Certificate domain name"
        return 1
    fi
    local cert_domain="${2}"

    if [ -z "${3}" ] ; then
        echo "Missing parameter 3: Webroot location"
        return 1
    fi
    local cert_webroot="${3}"

    echo "Obtaining certificate for ${cert_domain}"
    certbot certonly \
        --agree-tos \
        --domain "${cert_domain}" \
        --email "${admin_email}" \
        --keep-until-expiring \
        --max-log-backups 100 \
        --non-interactive \
        --renew-by-default \
        --webroot -w "${cert_webroot}"
}

function renew_certificate {
    if [ -z "${1}" ] ; then
        echo "Missing parameter 1: Webroot location"
        return 1
    fi
    local cert_webroot="${1}"

    echo "Renewing certificates registered on system."
    certbot renew \
        --non-interactive \
        --webroot -w "${cert_webroot}"
}

function process_certificates {
    if [ -z "${1}" ] ; then
        echo "Missing required parameter 1: Admin email"
        return 1
    fi
    local admin_email="${1}"

    if [ -z "${2}" ] ; then
        echo "Missing required parameter 2: Certificate domain name"
        return 1
    fi
    local cert_domain="${2}"

    if [ -z "${3}" ] ; then
        echo "Missing required parameter 3: Webroot location"
        return 1
    fi
    local cert_webroot="${3}"

    if check_for_cert "${cert_domain}"; then
        renew_certificate "${cert_webroot}"
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
        'e') admin_email="${OPTARG}" ;;
        'r') certificate_webroot="${OPTARG}" ;;
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
