#!/usr/bin/env bash

# Automated Let's Encrypt Script
# © 2016 Max Roeleveld <doenietzomoeilijk@gmail.com>
# See README.md for more info

set -e

# Make sure we have an SSL config
arch=$(uname -s)
if [ "$arch" == "Darwin" ]
then
    SSLCONF="/System/Library/OpenSSL/openssl.cnf"
elif [ "$arch" == "Linux" ]
then
    SSLCONF="/etc/ssl/openssl.cnf"
else
    echo "I only know about running on Mac OS X or Linux, sorry."
    exit 1
fi

# Check for acme-tiny
if [ ! -a "acme_tiny.py" ]
then
    echo "ERROR: acme_tiny.py is assumed to be in the same directory."
    echo "Please make sure it's there and try again."
    exit 1
fi

# Check for intermediate
if [ ! -f "certificates/intermediate.pem" ]
then
    echo "ERROR: missing certificates/intermediate.pem."
    echo "Please download the Let's Encrypt intermediate certificate from:"
    echo "  https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem"
    echo "and save it as intermediate.pem in the certificates/ directory."
    exit 1
fi

# Check for config
if [ ! -f "config.txt" ]
then
    echo "ERROR: config.txt is required but missing."
    exit 1
fi

# Make sure we have an account key
if [ ! -f "keys/account.key" ]
then
    echo "*** Generating account key..."
    openssl genrsa 4096 > "keys/account.key"
fi

# Run for all the domains
while IFS=' ' read domain sans
do
    domainkey="keys/${domain}-domain.key"
    if [ ! -f "$domainkey" ]
    then
        echo "*** Generating domain key for ${domain}..."
        openssl genrsa 4096 > "$domainkey"
    fi

    csrname="csrs/${domain}.csr"
    if [ ! -f "$csrname" ]
    then
        echo "*** Generating CSR for ${domain}..."
        openssl req -new -sha256 \
            -key $domainkey \
            -subj "/" \
            -reqexts SAN \
            -config <(cat $SSLCONF <(printf "[SAN]\nsubjectAltName=${sans}")) \
            > $csrname
    fi

    echo "*** Requesting certificate for ${domain}..."
    signedname="certificates/${domain}.crt"
    python acme_tiny.py \
        --account-key keys/account.key \
        --csr $csrname \
        --acme-dir ./challenges \
        > $signedname

    echo "*** Generating chained .pem file..."
    cat $signedname ./certificates/intermediate.pem > ${domain}-chained.pem

    echo "*** Done!\n"
done < config.txt
