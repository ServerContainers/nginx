# Docker production ready NGINX Container (servercontainers/nginx)
_maintained by ServerContainers_

[FAQ - All you need to know about the servercontainers Containers](https://marvin.im/docker-faq-all-you-need-to-know-about-the-marvambass-containers/)

## What is it

This Dockerfile (available as ___servercontainers/nginx___) gives you a NGINX on alpine. It is also possible to configure an auto lets encrypt certificate or self signed certificate and reverse proxy mechanism.

For Configuration of the Server you use environment Variables.

It's based on the [nginx:alpine](https://registry.hub.docker.com/_/nginx:alpine/) Image

View in Docker Registry [servercontainers/nginx](https://registry.hub.docker.com/u/servercontainers/nginx/)

View in GitHub [ServerContainers/nginx](https://github.com/ServerContainers/nginx)

## Environment variables and defaults

### NGINX

All options for the OpenSSL Stuff

* __NGINX\_CONFIG\_myconfigname__
    * multiple variables/confgurations possible by adding unique configname to NGINX_CONFIG_
    * adds a new nginx configuration
    * __server\_name__ is required
    * example: "server {server_name localhost; location / {root /data; index index.html;}}"
    * by default http redirects to ssl, ssl options get injected

to get an a+ rating at the qualys ssl test you need to set the __Strict-Transport-Security__
inside your nginx configuration like this:

    # only this domain
    add_header Strict-Transport-Security "max-age=31536000";
    # apply also on subdomains
    add_header Strict-Transport-Security "max-age=31536000; includeSubdomains";

### HTACCESS

* __HTACCESS\_ACCOUNT\_username__
    * multiple variables/accounts possible
    * adds a new htaccess account with the given username and the env value as password
    * htaccess file will be saved at __/conf/auth.htpasswd__

to enable authentication add the following to your nginx config _(inside or outside the location tag)_:

    auth_basic "Restricted Area"; auth_basic_user_file /conf/auth.htpasswd;


### ACME (Googles golang Let's Encrypt Client)

You need to accept the terms of the certificate authority, look inside to logs to find the URL where you get the current version.

    Terms:		 https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf

* __SSL\_ACME\_REGISTER\_MAIL__
    * set this to your email to get notifications from the certificate authority
    * needs to be set to enable the ACME client

### OpenSSL

All options for the OpenSSL Stuff

* __DH\_SIZE__
    * no default - needed only if you don't trust my shipped 4096 version.
    * if set a new one with given size is generated
    * only use a number as value
