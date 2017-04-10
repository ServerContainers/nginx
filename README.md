# Docker production ready NGINX Container (servercontainers/nginx)
_maintained by ServerContainers_

[FAQ - All you need to know about the servercontainers Containers](https://marvin.im/docker-faq-all-you-need-to-know-about-the-marvambass-containers/)

## What is it

This Dockerfile (available as ___servercontainers/nginx___) gives you a NGINX on alpine. It is also possible to configure an auto lets encrypt certificate or self signed certificate and reverse proxy mechanism.

For Configuration of the Server you use environment Variables.

It's based on the [alpine:3.5](https://registry.hub.docker.com/_/nginx:alpine/) Image

View in Docker Registry [servercontainers/nginx](https://registry.hub.docker.com/u/servercontainers/nginx/)

View in GitHub [ServerContainers/nginx](https://github.com/ServerContainers/nginx)

## Environment variables and defaults

### NGINX

All options for the OpenSSL Stuff

* __NGINX\_CONFIG\_1...n__
    * multiple variables possible by adding unique string to NGINX_CONFIG_
    * adds a new nginx configuration
    * __server\_name__ is required
    * example: "server {server_name localhost; location / {root /data; index index.html;}}"
    * by default http redirects to ssl, ssl options get injected

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
