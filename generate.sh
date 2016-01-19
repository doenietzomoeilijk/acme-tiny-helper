#!/usr/bin/env bash

# Automated Let's Encrypt Script
# Assumes config.txt to be present and contain lines in the format:
#   <domain> DNS:<domain>[,DNS:<other domain>...]

set -e

SSLCONF="/System/Library/OpenSSL/openssl.cnf"
# for Linux: SSLCONF="/etc/ssl/openssl.cnf"

generate ()
{
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

while IFS=' ' read domain sansblob 
do
    echo $domain
    echo $sansblob
    generate $domain $sansblob
    echo '-----'
done < config.txt
