#!/bin/bash

OPENSEARCH_URL="https://localhost:9200"
OPENSEARCH_INDEX="containers"
INTERVAL=30 

OPENSEARCH_USER="admin"
OPENSEARCH_PASS="BkK8[(SdJ*,#&G4g"

CONTAINERS="dummy-api envoy"

get_docker_stats() {
  docker stats --no-stream --format json $1
}

convert_to_bytes() {
  local value="$1"
  case "$value" in
    *KiB) echo $(awk "BEGIN {print ${value%KiB} / 1024}") ;;
    *MiB) echo $(awk "BEGIN {print ${value%MiB} * 1}") ;;
    *GiB) echo $(awk "BEGIN {print ${value%GiB} * 1024}") ;;
    *TiB) echo $(awk "BEGIN {print ${value%TiB} * 1024 * 1024}") ;;
    *B)   echo $(awk "BEGIN {print ${value%B} * 1}") ;;
    *kB)  echo $(awk "BEGIN {print ${value%kB} * 1000}") ;;
    *MB)  echo $(awk "BEGIN {print ${value%MB} * 1000 * 1000}") ;;
    *GB)  echo $(awk "BEGIN {print ${value%GB} * 1000 * 1000 * 1000}") ;;
    *TB)  echo $(awk "BEGIN {print ${value%TB} * 1000 * 1000 * 1000 * 1000}") ;;
    *)    echo "$value" ;;
  esac
}

format_stats() {
  local stats="$1"
  local timestamp="$2"

  # Container
  container_id=$(echo "$stats" | jq -r '.ID')
  container_name=$(echo "$stats" | jq -r '.Name')
  cpu_perc=$(echo "$stats" | jq -r '.CPUPerc' | sed 's/%//')
  mem_perc=$(echo "$stats" | jq -r '.MemPerc' | sed 's/%//')
  
  # Memory Usage and Limit
  mem_usage=$(echo "$stats" | jq -r '.MemUsage' | awk '{print $1}')
  mem_total=$(echo "$stats" | jq -r '.MemUsage' | awk '{print $3}')
  mem_usage_bytes=$(convert_to_bytes "$mem_usage")
  mem_total_bytes=$(convert_to_bytes "$mem_total")

  # Block I/O
  block_io_read=$(echo "$stats" | jq -r '.BlockIO' | awk '{print $1}')
  block_io_write=$(echo "$stats" | jq -r '.BlockIO' | awk '{print $3}')
  block_io_read_bytes=$(convert_to_bytes "$block_io_read")
  block_io_write_bytes=$(convert_to_bytes "$block_io_write")

  # Network I/O
  net_io_in=$(echo "$stats" | jq -r '.NetIO' | awk '{print $1}')
  net_io_out=$(echo "$stats" | jq -r '.NetIO' | awk '{print $3}')
  net_io_in_bytes=$(convert_to_bytes "$net_io_in")
  net_io_out_bytes=$(convert_to_bytes "$net_io_out")

  pids=$(echo "$stats" | jq -r '.PIDs')

  # Create a new JSON with structured data
  echo '{
    "timestamp": "'"$timestamp"'",
    "container_id": "'"$container_id"'",
    "container_name": "'"$container_name"'",
    "cpu_perc": '"$cpu_perc"',
    "mem_perc": '"$mem_perc"',
    "mem_usage_mbytes": '"$mem_usage_bytes"',
    "mem_total_mbytes": '"$mem_total_bytes"',
    "block_io_read_bytes": '"$block_io_read_bytes"',
    "block_io_write_bytes": '"$block_io_write_bytes"',
    "net_io_in_bytes": '"$net_io_in_bytes"',
    "net_io_out_bytes": '"$net_io_out_bytes"',
    "pids": '"$pids"'
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

