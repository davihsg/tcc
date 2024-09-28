#!/bin/bash

RAMP_UP=60 # 1 minute
ANOMALOUS_DELAY=300 # 5 minutes
RAMP_DOWN=840 # 14 minutes
DURATION=900 # 15 minutes

start_normal() {
  echo "[experiment] starting normal bot..."
  bash normal.sh &
  NORMAL_PID=$!
}

start_irregular() {
  echo "[experiment] starting irregular bot..."
  bash irregular.sh &
  IRREGULAR_PID=$!
}

start_anomalous() {
  echo "[experiment] starting anomalous bot..."
  bash anomalous.sh &
  ANOMALOUS_PID=$!
}

stop_bots() {
  echo "[experiment] stoping bots..."
  pkill -P $$
  # kill -s SIGINT $NORMAL_PID $IRREGULAR_PID $ANOMALOUS_PID 2>/dev/null
}

trap "echo '[experiment] interrupted!'; stop_bots; exit 1" SIGINT

echo "[experiment] starting at $(date -u)"

SLEEP=$RAMP_UP
echo "[experiment] sleeping for $SLEEP seconds"
sleep $SLEEP

start_normal
#start irregular

# waits ANOMALOUS_DELAY seconds before starting bot 3

SLEEP=$((ANOMALOUS_DELAY - RAMP_UP))
echo "[experiment] sleeping for $SLEEP seconds"
sleep $SLEEP

start_anomalous

SLEEP=$((RAMP_DOWN - ANOMALOUS_DELAY))
echo "[experiment] sleeping for $SLEEP seconds"
sleep $SLEEP

SLEEP=$((DURATION - RAMP_DOWN))
echo "[experiment] sleeping for $SLEEP seconds"
sleep $SLEEP

echo "[experiment] done at $(date -u)"

