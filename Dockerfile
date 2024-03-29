FROM debian:bullseye
LABEL github.user="ServerContainers"

ENV PATH="/container/scripts:${PATH}"

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get -q -y update \
 && apt-get -q -y install nginx-extras \
                          \
                          wget \
                          openssl \
                          ca-certificates \
                          procps \
 \
 && apt-get -q -y clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 \
 && rm /etc/nginx/sites-enabled/default \
 \
 && sed -i 's/access_log.*/access_log \/dev\/stdout;/g' /etc/nginx/nginx.conf \
 && sed -i 's/error_log.*/error_log \/dev\/stdout info;/g' /etc/nginx/nginx.conf \
 && sed -i 's/^pid/daemon off;\npid/g' /etc/nginx/nginx.conf \
 \
 && sed -i 's/ssl_protocols.*//g' /etc/nginx/nginx.conf \
 && sed -i 's/ssl_prefer_server_ciphers.*//g' /etc/nginx/nginx.conf \
 \
 && sed -i 's,include /etc/nginx/conf.d,include /conf/*.conf;\n        include /etc/nginx/conf.d,g' /etc/nginx/nginx.conf \
 \
 \
 && wget -O /iana-tlds.txt "http://data.iana.org/TLD/tlds-alpha-by-domain.txt" \
 \
 \
 && mkdir -p /conf /certs /data

EXPOSE 80 443

COPY /config/nginx/dh4096.pem /etc/nginx/dh.pem
COPY /config/nginx/conf.d /etc/nginx/conf.d/
COPY /config/nginx/snippets /etc/nginx/snippets/

COPY . /container/

HEALTHCHECK CMD ["docker-healthcheck.sh"]
ENTRYPOINT ["entrypoint.sh"]
CMD ["nginx"]
