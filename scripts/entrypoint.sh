#!/bin/sh

cat <<EOF
################################################################################

Welcome to the servercontainers/nginx

################################################################################

EOF


INITALIZED="/.entrypoint-initialized"

if [ ! -f "$INITALIZED" ]; then
  echo ">> CONTAINER: starting initialisation"

  ##
  # Diffie–Hellman Section
  ##
  if [ ! -z ${DH_SIZE+x} ]
  then
    DH_SIZE_ESCAPED=$(echo "$DH_SIZE" | sed 's/[^0-9]//g')
    echo ">> DH: generating new and overwriting old container $DH with size: $DH_SIZE_ESCAPED"
    openssl dhparam -out /etc/nginx/dh.pem "$DH_SIZE_ESCAPED"
  fi

  ##
  # ACME (Let's Encrypt section)
  ##
  if [ ! -z ${SSL_ACME_REGISTER_MAIL+x} ]
  then
    echo ">> ACME: register acme with mail: $SSL_ACME_REGISTER_MAIL"
    echo Y | acme reg -gen "mailto:$SSL_ACME_REGISTER_MAIL"
    echo ">> ACME: you need to accept the following terms"
    acme whoami | grep http
    acme update -accept
  fi

  ##
  # HTACCESS
  ##
  env | grep '^HTACCESS_ACCOUNT_' | while read I_ACCOUNT
    do
      ACCOUNT_NAME=$(echo "$I_ACCOUNT" | cut -d'=' -f1 | sed 's/HTACCESS_ACCOUNT_//g' | tr '[:upper:]' '[:lower:]')
      ACCOUNT_PASSWORD=$(echo "$I_ACCOUNT" | sed 's/^[^=]*=//g')
      
      if [ -z $(echo $ACCOUNT_PASSWORD | sed 's/^\$*\$.*//g') ]
      then
        echo ">> HTACCESS: adding account (hash provided): $ACCOUNT_NAME"
        PASSWORD_HASHED="$ACCOUNT_PASSWORD"
      else
        echo ">> HTACCESS: adding account (SHA-512 hashed): $ACCOUNT_NAME"
        PASSWORD_HASHED=$(echo "$ACCOUNT_PASSWORD" | mkpasswd -m sha-512)
      fi
      
      sed -i '/^'"$ACCOUNT_NAME"':/d' /conf/auth.htpasswd 2>/dev/null
      echo "$ACCOUNT_NAME"":""$PASSWORD_HASHED" >> /conf/auth.htpasswd

      unset $(echo "$I_ACCOUNT" | cut -d'=' -f1)
    done

  ##
  # NGINX RAW Config ENVs
  ##
  env | grep '^NGINX_RAW_CONFIG_' | while read I_CONF
    do
      rm /etc/nginx/conf.d/default.conf 2> /dev/null

      CONFD_CONF_NAME=$(echo "$I_CONF" | cut -d'=' -f1 | sed 's/NGINX_RAW_CONFIG_//g' | tr '[:upper:]' '[:lower:]')
      CONFD_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')

      echo "$CONFD_CONF_VALUE" >> "/conf/RAW_$CONFD_CONF_NAME.conf"
    done

  ##
  # NGINX Config ENVs
  ##
  env | grep '^NGINX_CONFIG_' | while read I_CONF
    do
      rm /etc/nginx/conf.d/default.conf 2> /dev/null

      CONFD_CONF_NAME=$(echo "$I_CONF" | cut -d'=' -f1 | sed 's/NGINX_CONFIG_//g' | tr '[:upper:]' '[:lower:]')
      CONFD_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')

      SERVER_NAMES=$(echo "$CONFD_CONF_VALUE" | sed -e 's/.*server_name \(.*\)/\1/' -e 's/;.*//g')
      SERVER_NAME=$(echo "$SERVER_NAMES" | awk '{print $1}')

      TLDs=$(sh -c "for i in \$(echo \"$SERVER_NAMES\" | sed 's,\.,/,g'); do basename \$i; done | sort | uniq  | tr '[:lower:]' '[:upper:]'")
      VALID_EXTERNAL_DOMAINS=$(for I_TLD in $TLDs; do grep "^$I_TLD\$" /iana-tlds.txt 2>/dev/null >/dev/null; echo $? ; done | uniq | sort -n | head -n1)

      if [ $VALID_EXTERNAL_DOMAINS -eq 0 ]
      then
        echo ">> ACME: register domains: $SERVER_NAMES"
        acme cert $SERVER_NAMES
        cp -f /root/.config/acme/*.key /certs && cp -f /root/.config/acme/*.crt /certs
        echo "acme cert -s 127.0.0.1:80 $SERVER_NAMES" >> /usr/local/bin/update-certs.sh
        echo "cp -f /root/.config/acme/*.key /certs && cp -f /root/.config/acme/*.crt /certs" >> /usr/local/bin/update-certs.sh
      else
        echo ">> OPENSSL SelfSigned: generating self signed cert for $SERVER_NAMES"

        cp /etc/ssl/openssl.cnf /tmp
        echo '[ subject_alt_name ]' >> /tmp/openssl.cnf
        echo -n 'subjectAltName = ' >> /tmp/openssl.cnf
        for I_SSL_DNS in $(echo "$SERVER_NAMES"); do echo -n "DNS:$I_SSL_DNS, "; done | sed 's/, $//g' >> /tmp/openssl.cnf
        echo '' >> /tmp/openssl.cnf

        openssl req -x509 -newkey rsa:4096 \
        -config /tmp/openssl.cnf \
        -extensions subject_alt_name \
        -days 3650 \
        -subj "/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=$SERVER_NAME" \
        -keyout "/certs/$SERVER_NAME.key" \
        -out "/certs/$SERVER_NAME.crt" \
        -nodes -sha256
      fi

      echo "server{listen 80; listen [::]:80; include /etc/nginx/snippets/letsencrypt-acme-challenge.conf; server_name $SERVER_NAMES; location / {return 301 https://$SERVER_NAME;}}" > "/conf/$CONFD_CONF_NAME.conf"
      echo "$CONFD_CONF_VALUE" | sed 's/server_name/listen 443 ssl; ssl on; ssl_certificate \/certs\/'"$SERVER_NAME"'.crt; ssl_certificate_key \/certs\/'"$SERVER_NAME"'.key; server_name/g' >> "/conf/$CONFD_CONF_NAME.conf"
      
      if [ ! -f "/certs/$SERVER_NAME.crt" ] || [ ! -f "/certs/$SERVER_NAME.key" ]; then openssl req -x509 -newkey rsa:4096 -days 3 -subj "/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=$SERVER_NAME" -keyout "/certs/$SERVER_NAME.key" -out "/certs/$SERVER_NAME.crt" -nodes -sha256; fi
    done

  ##
  # Default certificate generation
  ##
  if [ -e "/etc/nginx/conf.d/default.conf" ] && [ ! -e "/certs/cert.pem" ]
  then
    echo ">> OPENSSL SelfSigned: generating default self signed cert for localhost"
    openssl req -x509 -newkey rsa:4096 \
    -days 3650 \
    -subj "/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=localhost" \
    -keyout "/certs/key.pem" \
    -out "/certs/cert.pem" \
    -nodes -sha256
  fi

  ##
  # Default page generation
  ##
  if [ -e "/etc/nginx/conf.d/default.conf" ] && [ ! -e "/data/index.html" ]
  then
    echo ">> DATA: generating initial index.html"
    echo '<html><body><h1>ServerContainers/nginx</h1><a href="https://github.com/ServerContainers/nginx">ServerContainers/nginx @ GitHub.com</a></body></html>' > /data/index.html
  fi

  ##
  # Reload after cert update (sind SIGHUP to nginx)
  ##
  echo "cp -f /root/.config/acme/*.key /certs && cp -f /root/.config/acme/*.crt /certs" >> /usr/local/bin/update-certs.sh
  echo "kill -1 1" >> /usr/local/bin/update-certs.sh

  touch "$INITALIZED"
else
  echo ">> CONTAINER: already initialized - direct start of nginx"
fi

##
# Update Certificates
##
if [ $(find /certs/*.crt | wc -l) -gt 0 ]
then
  sh -c "sleep 60; while true; do update-certs.sh; sleep 1d; done" &
fi

##
# CMD
##
echo ">> CMD: exec docker CMD"
echo "$@"
exec "$@"
