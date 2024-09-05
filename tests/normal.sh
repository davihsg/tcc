#!/bin/bash

HOST="https://localhost:10000"
URI="/items"
INTERVAL=20 
USER="1"
CERTS_FOLDERS="$HOME/tcc/users"
CACERT="$CERTS_FOLDERS/bundle.$USER.pem"
CERT="$CERTS_FOLDERS/svid.$USER.pem"
KEY="$CERTS_FOLDERS/svid.$USER.key"

function send_request {
  curl -s -k -o /dev/null -w "%{http_code}" \
    -X GET "$HOST$URI" \
    --cacert $CACERT --cert $CERT --key $KEY
}

stop() {
  echo "[normal] stopping..."
  pkill -P $$
  exit 0
}

trap "stop" SIGINT
trap "stop" SIGTERM

while true; do
  RESPONSE_CODE=$(send_request)
  
  if [ "$RESPONSE_CODE" -eq 429 ]; then
    echo "[normal] Received 429 Too Many Requests. Waiting for 1 minute"
    sleep 60  # waits 1 minute in case of 429
  else
    echo "[normal] Request sent. Got response: $RESPONSE_CODE"
    sleep $INTERVAL
  fi
done

