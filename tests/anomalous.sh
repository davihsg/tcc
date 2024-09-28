#!/bin/bash

HOST="https://localhost:10000"
URI="/items"
CERTS_FOLDERS="$HOME/tcc/certs"
CACERT="$CERTS_FOLDERS/ca.crt"
CERT="$CERTS_FOLDERS/anomalous.crt"
KEY="$CERTS_FOLDERS/anomalous.key"
TARGETS_FILE="anomalous_targets.txt"
REPORTS_FILE="anomalous.bin"
INTERVAL=1
RATE=500
WORKERS=100
DURATION="9m"

attack() {
  vegeta attack \
    -cert=$CERT \
    -key=$KEY \
    -targets=$TARGETS_FILE \
    -root-certs=$CACERT \
    -max-body=0 \
    -rate=$RATE \
    -workers=$WORKERS \
    -duration=$DURATION > $RESULTS_FILE
}

stop() {
  echo "[anomalous] stopping attack..."
  pkill -P $$
  exit 0
}

echo "[anomalous] creating targets file"

if [ ! -f "$TARGETS_FILE" ]; then
  echo "GET $HOST$URI" > $TARGETS_FILE
  echo "[anomalous] targets created with default route"
else
  echo "[anomalous] targets already exists, skipping..."
fi

trap "stop" SIGINT
trap "stop" SIGTERM

echo "[anomalous] starting DDoS attack for $DURATION"

attack

echo "[anomalous] DDoS attack finished (for now)"

