FROM nginx:alpine
LABEL github.user="ServerContainers"

ENV PATH="/container/scripts:${PATH}"

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
 && wget -O /iana-tlds.txt "http://data.iana.org/TLD/tlds-alpha-by-domain.txt" \
 \
 \
 && openssl dhparam -out /etc/nginx/dh.pem 4096

EXPOSE 80 443

COPY conf.d /etc/nginx/conf.d/
COPY snippets /etc/nginx/snippets/

COPY . /container/

HEALTHCHECK CMD ["docker-healthcheck.sh"]
ENTRYPOINT ["entrypoint.sh"]
CMD ["nginx"]
