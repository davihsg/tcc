#!/bin/bash

HOST="http://localhost:10002"
URI="/items"
INTERVAL=10 
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

while true; do
  RESPONSE_CODE=$(send_request)
  
  if [ "$RESPONSE_CODE" -eq 429 ]; then
    echo "Received 429 Too Many Requests. Waiting for 1 minute."
    sleep 60  # waits 1 minute in case of 429
  else
    echo "Request sent by Normal Bot. Got response: $RESPONSE_CODE"
    sleep $INTERVAL
  fi
done

