#!/bin/bash

OPENSEARCH_URL="https://localhost:9200"
OPENSEARCH_INDEX="containers"
INTERVAL=10

OPENSEARCH_USER="admin"
OPENSEARCH_PASS="BkK8[(SdJ*,#&G4g"

CONTAINERS="dummy-api envoy webdis"

get_docker_stats() {
  docker stats --no-stream --format json $1
}

format_stats() {
  local stats="$1"
  local timestamp="$2"

  # Container
  container_id=$(echo "$stats" | jq -r '.ID')
  container_name=$(echo "$stats" | jq -r '.Name')
  cpu_perc=$(echo "$stats" | jq -r '.CPUPerc' | sed 's/%//')
  mem_perc=$(echo "$stats" | jq -r '.MemPerc' | sed 's/%//')

  # Create a new JSON with structured data
  echo '{
    "timestamp": "'"$timestamp"'",
    "container_id": "'"$container_id"'",
    "container_name": "'"$container_name"'",
    "cpu_perc": '"$cpu_perc"',
    "mem_perc": '"$mem_perc"'
  }' | jq .
}

send_to_opensearch() {
  local container=$1
  curl -k -X POST "$OPENSEARCH_URL/$OPENSEARCH_INDEX/_doc" \
    -H "Content-Type: application/json" \
    -d @/tmp/monitoring_$container.json \
    -u "$OPENSEARCH_USER:$OPENSEARCH_PASS"
}

while true; do
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "[$timestamp] starting collecting resources data from containers: $CONTAINERS"

  for container in $CONTAINERS; do
    stats=$(get_docker_stats "$container")

    formatted_stats=$(format_stats "$stats" "$timestamp")

    echo $formatted_stats > /tmp/monitoring_$container.json

    send_to_opensearch $container

    echo ''

    rm /tmp/monitoring_$container.json
  done

  echo "sleeping for $INTERVAL seconds"
  
  sleep $INTERVAL
done

