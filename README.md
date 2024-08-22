![opensearch+envoy](https://github.com/davihsg/tcc/raw/main/assets/opensearch+envoy.png)
# Opensearch and Envoy

This repository presents a simple, yet sophisticated, implementation of access control using Envoy Proxy and Opensearch.

## Architecture Overview

![architecture-overview](https://github.com/davihsg/tcc/raw/main/assets/architecture-overview.png)

Here's a brief explanation of each step in the flow:

1. **User Request:**  
   An authenticated user sends a request to the Envoy proxy, including its SVID certificate for identification and authentication. The SVID helps in determining the user's identity securely.

2. **Rate limiting check:**  
   Envoy runs a Lua script to check if the user has reached a predefined request limit. It does this by fetching information from a Redis database, using Webdis as an intermediary. Webdis is employed because Envoy's Lua library supports HTTP/HTTPS natively, not TCP, making it necessary to access Redis in this manner. If the user hasn't exceeded the limit, Envoy processes the request normally. If the limit is exceeded, Envoy returns a `429 Too Many Requests` response to the user.

3. **Forwarding to API:**  
   If the request is valid and within the allowed limit, Envoy forwards it to the API for further processing.

4. **Logging to OpenSearch:**  
   Envoy sends access logs in JSON format to OpenSearch through Fluent Bit. These logs contain information about the request processed, helping in monitoring and analysis.

5. **Alert Triggering:**  
   OpenSearch processes the access logs, and if any predefined conditions or thresholds are met, it triggers a monitor alert. This alert is sent as a notification to an alerting API, including information about the severity of the alert and the user's spiffeID.

6. **Alert Handling:**  
   The Alerting API processes the notification and updates the relevant information in the Redis database. To update the Redis database, the API sends an HTTPS request to Envoy, which downgrades the connection from HTTPS to HTTP and forwards the request to Webdis. Envoy acts as a reverse proxy in this scenario.

This flow ensures secure access, request rate limiting, logging, and monitoring with automatic updates based on alerts.

## Tutorial: Setting Up and Running the System

This guide will help you set up and run the system using Docker Compose. Docker Compose is ideal for this setup because of its built-in DNS, which simplifies communication between services. The system is organized into two networks: 
- **webdis** (includes Envoy and Webdis containers)
- **world** (includes OpenSearch, Alerting API, Envoy, API, and Fluent Bit)

### Prerequisites
Ensure you have Docker and Docker Compose installed on your system.

### Step 1: Starting the services

```bash
docker-compose up -d
```

### Step 2: Set Up OpenSearch

1. **Create an Index for Envoy Access Logs:**
   - You need to create a mapping in OpenSearch for storing Envoy’s access logs. This index will be the same set up in Fluent Bit. 
   - You can create the index and its mapping using a `curl` command, or by refreshing the current index. Check [envoy_mapping.json](https://github.com/davihsg/tcc/tree/main/opensearch/envoy_mapping.json).

   Example `curl` command for creating an index:
   ```bash
   curl -X PUT "http://opensearch:9200/envoy" -H 'Content-Type: application/json' -d'
   {
     "mappings": {
       "properties": {
         "severity": { "type": "keyword" },
         "message": { "type": "text" },
         ...
       }
     }
   }'
   ```

2. **Create an Index for Alerts:**
   - This index will store alert documents sent by the Alerting API for further analysis.
   - You can create the index and its mapping using a `curl` command, or by refreshing the current index. Check [envoy-alerts_mapping.json](https://github.com/davihsg/tcc/tree/main/opensearch/envoy-alerts_mapping.json).

   Example `curl` command:
   ```bash
   curl -X PUT "http://opensearch:9200/envoy-alerts" -H 'Content-Type: application/json' -d'
   {
     "mappings": {
       "properties": {
         "severity": { "type": "keyword" },
         "message": { "type": "text" },
         ...
       }
     }
   }'
   ```

3. **Create a Custom Webhook Channel:**
   - Set up a custom webhook in OpenSearch to communicate with the Alerting API.
   - The webhook should be configured with the Alerting API URL. It should like this:
   ```json
   {
     "config_id": "OqskdpEBl4KNMQxhQMg1",
     "last_updated_time_ms": 1724264264843,
     "created_time_ms": 1724263972913,
     "config": {
       "name": "alerting-api",
       "description": "",
       "config_type": "webhook",
       "is_enabled": true,
       "webhook": {
         "url": "http://alerting:31415/alert",
         "header_params": {
           "Content-Type": "application/json"
         },
         "method": "POST"
       }
     }
   }
   ```

4. **Create Monitors and Triggers:**
   - In OpenSearch, create monitors to watch the logs and generate alerts based on specific conditions.
   
   The index mappings may have nested fields, especially the keyword ones. Opensearch Dashboards UI has problems when showing the group by options because of it, so the monitor should be created using extraction query or via curl. Here is an [example](https://github.com/davihsg/tcc/tree/main/opensearch/monitors/sum_duration_monitor.json) of how it should look like.

   - Create triggers for the monitor.

   Documentation is quite scarce in this area, so you should opted to create them using an extraction query or via curl. Here is an [example](https://github.com/davihsg/tcc/tree/main/opensearch/monitors/trigger_condition.json) of how its condition should look like.

   ```json
   {
     "buckets_path": {
       "sum_duration": "sum_duration"
     },
     "parent_bucket_path": "terms_agg",
     "script": {
       "source": "params.sum_duration > 100",
       "lang": "painless"
     },
     "gap_policy": "skip"
   }

   ```

   - Add actions to the triggers that will send a JSON message with alert details when new alerts are generated or completed. This message will be sent via the webhook channel you configured earlier.

   Even though you can set the custom webhook to send an HTTP request with `Content-Type: application/json`, OpenSearch just sends the message as the body, so you must set the json yourself.

   Example trigger alert message:
   ```json
   {
     "alerts": [
       {{#ctx.newAlerts}}
       {
         "id": "{{id}}",
         "spiffe_id": "{{bucket_keys}}",
         "monitor_name": "{{ctx.monitor.name}}",
         "severity": {{ctx.trigger.severity}},
         "period_start": "{{ctx.periodStart}}",
         "period_end": "{{ctx.periodEnd}}",
         "state": "ACTIVE",
         "global_scope": false
       },
       {{/ctx.newAlerts}}
       {{#ctx.completedAlerts}}
       {
         "id": "{{id}}",
         "spiffe_id": "{{bucket_keys}}",
         "monitor_name": "{{ctx.monitor.name}}",
         "severity": {{ctx.trigger.severity}},
         "period_start": "{{ctx.periodStart}}",
         "period_end": "{{ctx.periodEnd}}",
         "state": "COMPLETED",
         "global_scope": false
       },
       {{/ctx.completedAlerts}}
       null
     ]
   }
   ```

### Step 3: Set Up Envoy

1. **Configure Listener for Access Logs:**
   - Modify Envoy’s configuration to include a listener filter that outputs logs in JSON format. This ensures that Fluent Bit can easily parse and forward these logs to OpenSearch.

   The log must contain a spiffe_id field. See this [example](https://github.com/davihsg/tcc/blob/main/envoy/envoy.yaml#L122).

   Example:
   ```yaml
   - name: envoy.http_connection_manager
     config:
       access_log:
       - name: envoy.file_access_log
         config:
           path: /dev/stdout
           json_format: 
             ...
             spiffe_id: "%DOWNSTREAM_PEER_URI_SAN%"
   ```

2. **Add Lua Script for Rate Limiting:**
   - On the API listener, add an HTTP Lua filter that runs the `ratelimit.lua` script. This script will handle checking the rate limits by querying the Redis database via Webdis.

   Example:
   ```yaml
   - name: envoy.filters.http.lua
     typed_config:
       "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
       default_source_code:
         filename: /etc/lua/ratelimit.lua
   ```

   The [lua script](https://github.com/davihsg/tcc/blob/main/envoy/lua/ratelimit.lua) just gets the value from two keys: the spiffe id, and a global key. If either one of them is greater than 0, meaning that there is an ongoing alert, Envoy returns 429 - Too Many Requests - immediatly. Otherwise, the request is processed normally.

3. **Set Up HTTPS to HTTP Proxying for Webdis:**
   - Add a listener in Envoy that downgrades incoming HTTPS requests to HTTP, forwarding them to the Webdis cluster. Ensure that only the necessary routes are exposed and protected. Set up a transport socker as you wish.

   Example:
   ```yaml
   listener:
   ...
    - name: webdis
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 8379
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                codec_type: AUTO
                stat_prefix: ingress_http
                common_http_protocol_options:
                  idle_timeout: 1s
                route_config:
                  name: route
                  virtual_hosts:
                    - name: webdis
                      domains: ["*"]
                      routes:
                        - match:
                            safe_regex:
                              regex: "/(GET|INCR|DECR)/spiffe:%2F%2Fdhsg.com%2F[^/]+$"
                          route:
                            cluster: webdis
                        - match:
                            safe_regex:
                              regex: "/(GET|INCR|DECR)/global_scope"
                          route:
                            cluster: webdis
       http_filters:
        - name: envoy.filters.http.router
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

    ...

   cluster:
    - name: webdis
      connect_timeout: 0.25s
      type: STRICT_DNS
      load_assignment:
        cluster_name: webdis
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: webdis
                      port_value: 7379

   ```

### Step 4: Accessing the API

The rate limiting is now set up. Users can access the API through Envoy by passing the appropriate SVID certificate with their requests.

Example request:
```bash
curl --cacert bundle.0.pem --cert svid.0.pem --key svid.0.key "https://localhost:10002/items" -k
   ```

## Authors

- [davihsg](https://github.com/davihsg)
