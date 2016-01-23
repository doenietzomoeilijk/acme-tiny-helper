# acme-tiny-helper

Shell script to do as much heavy lifting for acme-tiny as possible.

This script requires [acme-tiny](https://github.com/diafygi/acme-tiny),
and is based on that project's README file.

## How to use

* This script assumes a file `config.txt` to be present, containing a line
  for each domain + it's altnames you want to request certificates for:

  ```
  domain.tld DNS:domain.tld,DNS:www.domain.tld,DNS:altname.domain.tld
  ```
  
  At this moment the limit is 100 altnames per domainname, but that's up to
  Let's Encrypt.

* A second assumption is that anything in the `challenges/` directory is 
  served by your web server on `/.well-known/acme-challenge/`. The acme-tiny
  README has an example for Nginx. Test this before you start spamming
  Let's Encrypt with bogus requests!

* Finally, it requires acme_tiny.py and the Let's Encrypt intermediate
  certificate to be present; acme_tiny.py is expected in the current directory,
  the intermediate certificate is expected in certificates/intermediate.pem.

After that, it's a matter of running

```bash
./generate.sh
```

and wait for the magic to happen. CSR files will be generated into csrs/, keys
will be generated in keys/, and certificates will be stored in certificates/.
CSRs and account/domain keys will be re-used.

## In case of problems...

This is a quick and dirty shell script because I wanted to be able to 
run things from a cron job. Use at your own risk, if this script breaks
things you get to keep both parts.

If you run into a problem and have a fix, a pull request is always welcome.

## TO DO

* Possibly the option of specifying a domain from your config file, to have it
  run only for that domain.
