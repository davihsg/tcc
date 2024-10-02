#!/bin/bash

HOST="https://localhost:10000"
URI="/items"
INTERVAL=20 
USER="1"
CERTS_FOLDERS="$HOME/programacao/tcc/tcc/certs"
CACERT="$CERTS_FOLDERS/ca.crt"
CERT="$CERTS_FOLDERS/normal.crt"
KEY="$CERTS_FOLDERS/normal.key"
TARGETS_FILE="normal_targets.txt"
REPORTS_FILE="normal.bin"
INTERVAL=1
RATE="15/1m"
WORKERS=1
DURATION="13m"

function start {
  vegeta attack \
    -name="normal" \
    -cert=$CERT \
    -key=$KEY \
    -targets=$TARGETS_FILE \
    -root-certs=$CACERT \
    -max-body=0 \
    -rate=$RATE \
    -workers=$WORKERS \
    -duration=$DURATION | tee normal.bin | vegeta encode --to=json --output=normal.json
}

stop() {
  echo "[normal] stopping..."
  pkill -P $$
  exit 0
}

echo "[normal] creating targets file"

if [ ! -f "$TARGETS_FILE" ]; then
  echo "GET $HOST$URI" > $TARGETS_FILE
  echo "[normal] targets created with default route"
else
  echo "[normal] targets already exists, skipping..."
fi

trap "stop" SIGINT
trap "stop" SIGTERM

echo "[normal] starting..."

start

echo "[normal] stopping..."
