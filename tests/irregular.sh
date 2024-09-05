#!/bin/bash

HOST="https://localhost:10000"
URI="/items"
BASE_INTERVAL=10
VARIATION=5
USER="0"
CERTS_FOLDERS="$HOME/tcc/users"
CACERT="$CERTS_FOLDERS/bundle.$USER.pem"
CERT="$CERTS_FOLDERS/svid.$USER.pem"
KEY="$CERTS_FOLDERS/svid.$USER.key"

function get_random_interval {
  echo $(( BASE_INTERVAL + RANDOM % (VARIATION * 2 + 1) - VARIATION ))
}

function send_request {
  curl -s -k -o /dev/null -w "%{http_code}" \
    -X GET "$HOST$URI" \
    --cacert $CACERT --cert $CERT --key $KEY
}

stop() {
  echo "[irregular] stopping..."
  pkill -P $$ -9
  exit 0
}

trap "stop" SIGINT
trap "stop" SIGTERM

while true; do
  RESPONSE_CODE=$(send_request)

  if (( RANDOM % 10 == 0 )); then  # 10%
    echo "[irregular] Duplicated request sent"
    RESPONSE_CODE=$(send_request)
  fi
  
  if [ "$RESPONSE_CODE" -eq 429 ]; then
    echo "[irregular] Received 429 Too Many Requests. Waiting for 30 seconds"
    sleep 30  # waits 30 seconds in case of 429
  else
    echo "[irregular] Request sent. Got response: $RESPONSE_CODE"
    INTERVAL=$(get_random_interval)
    sleep $INTERVAL
  fi
done

