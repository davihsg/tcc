#!/bin/bash

HOST="http://localhost:10002"
URI="/items"
BASE_INTERVAL=15
VARIATION=5
USER="2"
CERTS_FOLDERS="$HOME/tcc/users"
CACERT="$certs_folders/bundle.$USER.pem"
CERT="$certs_folders/svid.$USER.pem"
KEY="$certs_folders/svid.$USER.key"

function send_request {
  curl -s -k -o /dev/null -w "%{http_code}" \
    -X GET "$HOST$URI" -H "Content-Type: application/json" \
    --cacert $CACERT --cert $CERT --key $KEY
}

function send_request {
  curl -s -o /dev/null -w "%{http_code}" -X GET "$HOST$URI" -H "Content-Type: application/json" --cacert $CACERT --cert $CERT --key $KEY
}

while true; do
  RESPONSE_CODE=$(send_request)

  if (( RANDOM % 10 == 0 )); then  # 10%
    echo "Duplicated request sent"
    RESPONSE_CODE=$(send_request)
  fi
  
  if [ "$RESPONSE_CODE" -eq 429 ]; then
    echo "Received 429 Too Many Requests. Waiting for 30 seconds."
    sleep 30  # waits 30 seconds in case of 429
  else
    echo "Request sent by Slighty Irregular Bot. Got response: $RESPONSE_CODE"
    INTERVAL=$(get_random_interval)
    sleep $INTERVAL
  fi
done

