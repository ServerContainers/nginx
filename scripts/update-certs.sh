#!/bin/sh

echo -n ">> UPDATING CERTS: "
date +'%Y %b %d'

FUTURE_DAYS="/tmp/30days"

echo ">> UPDATING CERTS: generating future days file"
rm -f "$FUTURE_DAYS" 2> /dev/null
for DAY in $(seq 30)
do
  GAP=$(expr 86400 \* $DAY) # one day multiplied by DAY
  CURRENT_TIMESTAMP=$(date +%s)
  DATE=$(echo expr $CURRENT_TIMESTAMP + $GAP | sh | awk '{print "date -d @"$1" +'"'"'%Y %b %d'"'"'"}' | sh)
  echo $DATE >> "$FUTURE_DAYS"
done

echo ">> UPDATING CERTS: checking lifetime"

UPDATE=0

for CERT in $(find /certs/*.crt)
do
  NOT_AFTER=$(openssl x509 -in $CERT  -noout -dates | grep notAfter | cut -d= -f2 | awk '{print $4, $1, $2}')
  echo ">> UPDATING CERTS: checking cert '$CERT' notAfter $NOT_AFTER"
  if grep "$NOT_AFTER" "$FUTURE_DAYS"
  then
    DAYS_LEFT=$(grep -n "$NOT_AFTER" "$FUTURE_DAYS" | cut -d: -f1)
    echo ">> UPDATING CERTS: cert '$CERT' needs update - only $DAYS_LEFT days left"
    UPDATE=1
  fi
done

if [ "$UPDATE" -eq "0" ]
then
  echo ">> UPDATING CERTS: no certs to update - exiting"
  exit 0
fi
