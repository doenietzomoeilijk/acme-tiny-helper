#!/usr/bin/env bash

# Automated Let's Encrypt Script
# Assumes config.txt to be present and contain lines in the format:
#   <domain> DNS:<domain>[,DNS:<other domain>...]

set -e

generate ()
{
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

    echo "Generate: domain=$1 sans=$2 SSLCONF=$SSLCONF"

    domainkey="domain-${1}.key"
    if [ ! -f "$domainkey" ]
    then
        echo "*** Generating domain key for ${1}..."
        openssl genrsa 4096 > "$domainkey"
    fi

    csrname="domain-${1}.csr"
    if [ ! -f "$csrname" ]
    then
        echo "*** Generating CSR for ${1}..."
        openssl req -new -sha256 \
            -key $domainkey \
            -subj "/" \
            -reqexts SAN \
            -config <(cat $SSLCONF <(printf "[SAN]\nsubjectAltName=${2}")) \
            > $csrname
    fi

    echo "*** Requesting certificate for ${1}..."
    signedname="signed-${1}.crt"
    python acme_tiny.py \
        --account-key letsencrypt.key \
        --csr $csrname \
        --acme-dir ./challenges \
        > $signedname

    echo "*** Generating chained .pem file..."
    cat $signedname ./intermediate.pem > chained-${1}.pem

    echo "*** Done!\n"
}

# Sanity checks
if [ ! -a "acme_tiny.py" ]
then
    echo "ERROR: acme_tiny.py is assumed to be in the same directory."
    echo "Please make sure it's there and try again."
    exit 1
fi
if [ ! -f "intermediate.pem" ]
then
    echo "ERROR: intermediate.pem is assumed to be in the same directory."
    echo "Please download the Let's Encrypt intermediate certificate from:"
    echo "  https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem"
    echo "and save it as intermediate.pem in this directory."
    exit 1
fi
if [ ! -f "config.txt" ]
then
    echo "ERROR: config.txt is required but missing."
    exit 1
fi

# Run!
while IFS=' ' read domain sansblob 
do
    generate $domain $sansblob
done < config.txt
