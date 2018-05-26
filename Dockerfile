FROM nginx:alpine
LABEL github.user="ServerContainers"

ENV ACME_CONFIG=/root/.config/acme

RUN apk update \
 && apk add wget \
            openssl \
            ca-certificates \
 && rm -f /var/cache/apk/* \
 \
 \
 && sed -i 's/access_log.*/access_log \/dev\/stdout;/g' /etc/nginx/nginx.conf \
 && sed -i 's/error_log.*/error_log \/dev\/stdout info;/g' /etc/nginx/nginx.conf \
 && sed -i 's/^pid/daemon off;\npid/g' /etc/nginx/nginx.conf \
 \
 && sed -i 's,include /etc,include /conf/*.conf;\n    include /etc,g' /etc/nginx/nginx.conf \
 \
 \
 && if uname -m | grep arm; then export ACME_URL='https://github.com/google/acme/releases/download/1.1.1/acme-linux-arm'; \
 else export ACME_URL='https://github.com/google/acme/releases/download/1.1.1/acme-linux-amd64'; fi \
 \
 && export ACME_BINARY='/usr/local/bin/acme' \
 && wget -O "$ACME_BINARY" "$ACME_URL" \
 && chmod a+x "$ACME_BINARY" \
 && mkdir -p /root/.config/acme /conf /certs /data \
 \
 \
 && wget -O /iana-tlds.txt "http://data.iana.org/TLD/tlds-alpha-by-domain.txt" \
 \
 \
 && openssl dhparam -out /etc/nginx/dh.pem 4096

EXPOSE 80 443

COPY conf.d /etc/nginx/conf.d/
COPY snippets /etc/nginx/snippets/
COPY scripts /usr/local/bin/

HEALTHCHECK CMD ["docker-healthcheck.sh"]
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx"]
