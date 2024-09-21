![opensearch+envoy](https://github.com/davihsg/tcc/raw/main/assets/opensearch+envoy.png)
# Opensearch and Envoy

This repository presents a simple, yet sophisticated, implementation of access control using Envoy Proxy and Opensearch.

## Architecture Overview

![architecture-overview](https://github.com/davihsg/tcc/raw/main/assets/architecture-overview.png)

Here's a brief explanation of each step in the flow:

1. **User Request:** An authenticated user sends a request to the Envoy proxy, including its SVID certificate for identification and authentication. The SVID helps in determining the user's identity securely.

2. **Rate limiting check:** Envoy runs a Lua script to check if the user has reached a predefined request limit. It does this by fetching information from a Redis database, using Webdis as an intermediary. Webdis is employed because Envoy's Lua library supports HTTP/HTTPS natively, not TCP, making it necessary to access Redis in this manner. If the user hasn't exceeded the limit, Envoy processes the request normally. If the limit is exceeded, Envoy returns a `429 Too Many Requests` response to the user.

3. **Forwarding to API:** If the request is valid and within the allowed limit, Envoy forwards it to the API for further processing.

4. **Logging to OpenSearch:** Envoy sends access logs in JSON format to OpenSearch through Fluent Bit. These logs contain information about the request processed, helping in monitoring and analysis.

5. **Log Processing and Alerting:** Once the logs are stored in OpenSearch, they are analyzed. If any predefined conditions are met (e.g., exceeding request limits or unusual access patterns), an alert is triggered. This alert system is part of a monitoring mechanism in OpenSearch. When triggered, a notification is sent back to the Envoy instance.

6. **Alert Processing:** Envoy has a dedicated listener to process the alert notifications. When Envoy receives an alert, another Lua script is executed. This script updates the user's information stored in the Webdis + Redis container. These updates may include modifying the rate limit status or flagging specific users based on the alert details, allowing for dynamic adjustments to user access in response to system conditions.

This flow ensures secure access, request rate limiting, logging, and monitoring with automatic updates based on alerts.

## Tutorial: Setting Up and Running the System

### Prerequisites

Ensure you have Docker and Docker Compose installed on your system. If not, you can check out [Docker Documentation](https://docs.docker.com/engine/install/).

### 1. SPIRE Server Setup

### 1.1. CA Certificates and SPIRE Server Setup

Before we integrate SPIRE with Envoy, you need to ensure that the **CA certificates** and **SPIRE server** are set up. SPIRE will handle issuing and managing **SPIFFE IDs**, which Envoy will use for mutual TLS authentication.

For a detailed guide on how to create CA certificates and set up the SPIRE server, please refer to the links below:

1. [**Create CA certificates**](certs/README.md) for signing SPIRE server certificates.
2. [**Set up a SPIRE server and agent**](spire/README.md) to issue **SPIFFE IDs**.

#### 1.2. Setting up SPIRE Agent with Envoy Integration

The next step is to set up **SPIRE agent** and integrate it with **Envoy** to use **SPIFFE IDs** for mutual TLS (mTLS) communication.

Here’s how to integrate SPIRE and Envoy using the provided configurations.

1. **SPIRE Agent and Envoy Socket Configuration**

   In your Envoy configuration, you’ll need to set up communication between the **SPIRE agent** and **Envoy** via a Unix domain socket. SPIRE will provide **SPIFFE IDs** through its SDS (Secret Discovery Service), and Envoy will use these SPIFFE-based secrets for mTLS.

   Add the following to your Envoy configuration to define a cluster for **SPIRE agent** communication:

   ```yaml
   clusters:
   - name: spire_agent
     connect_timeout: 0.25s
     http2_protocol_options: {}
     load_assignment:
       cluster_name: spire_agent
       endpoints:
         - lb_endpoints:
             - endpoint:
                 address:
                   pipe:
                     path: /tmp/spire-agent/public/api.sock
   ```

   This sets up Envoy to communicate with the SPIRE agent via a Unix socket (`/tmp/spire-agent/public/api.sock`). The SPIRE agent will be running locally on the same machine as the Envoy instance.

2. **Envoy's transport socket**
    
    In your Envoy configuration, use the following transport socket configuration for **downstream TLS context** to request mTLS using SPIFFE IDs.

    ```yaml
      transport_socket:
        name: envoy.transport_sockets.tls
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
          require_client_certificate: true
          common_tls_context:
            tls_certificate_sds_secret_configs:
              - name: spiffe://dhsg.com/envoy-api
                sds_config:
                  resource_api_version: V3
                  api_config_source:
                    api_type: GRPC
                    transport_api_version: V3
                    grpc_services:
                      envoy_grpc:
                        cluster_name: spire_agent
            validation_context_sds_secret_config:
              name: "spiffe://dhsg.com"
              sds_config:
                resource_api_version: V3
                api_config_source:
                  api_type: GRPC
                  transport_api_version: V3
                  grpc_services:
                    envoy_grpc:
                      cluster_name: spire_agent
    ```

3. **Docker Setup for Envoy and SPIRE Agent**

    The SPIRE agent socket will be mounted inside the Envoy container for communication.

    Here’s an example `docker-compose.yml` configuration:

    ```yaml
    services:
      envoy:
        container_name: envoy
        image: envoyproxy/envoy:contrib-v1.29.1
        volumes:
          ...
          - /tmp/spire-agent/public:/tmp/spire-agent/public  # Mount SPIRE agent socket
    ```

### 2. Starting the services

Every component of the system is running on a docker container, except for the SPIRE instances. Docker Compose is ideal for this setup because of its built-in DNS, which simplifies communication between services.

1. Networks

    The system is organized into two networks: 

    - **webdis** (includes Envoy and Webdis containers)
    - **world** (includes OpenSearch, Envoy, API, and Fluent Bit)

2. Containers

    The system has six containers:

    - **opensearch** on single-node mode;
    - **opensearch dashboards** to set up alerts;
    - **fluent bit** to ingest logs from envoy into opensearch;
    - **dummy api** to simulate a real upstream service;
    - **envoy** to handle communication between components;
    - **webdis (+ redis)** for storing data and fetching Redis via HTTP;

3. Volumes

    There is only one volume:

    - **opensearch-data** for storing opensearch in disk (and not lose everything - yes, this happened)

To start all containers, simple run:

```bash
docker-compose up -d
```

### 3. Ingest Envoy Access Log into Opensearch

#### 3.1. Configure Listener for Access Logs

Modify Envoy’s configuration to include a listener filter that outputs logs in JSON format. This ensures that Fluent Bit can easily parse and forward these logs to OpenSearch.

The log must contain a `spiffe_id` field. See this [example](https://github.com/davihsg/tcc/blob/main/envoy/envoy.yaml#L122). Adding useful information such as listener and duration is really useful since you can create different monitors with them. It is strongly recommended checking the [example](https://github.com/davihsg/tcc/blob/main/envoy/envoy.yaml#L122).

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

#### 3.2. Add Lua Script for Rate Limiting

On the API listener, add an HTTP Lua filter that runs the `ratelimit.lua` script. This script will handle checking the rate limits by querying the Redis database via Webdis.

Example:
```yaml
- name: envoy.filters.http.lua
 typed_config:
   "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
   default_source_code:
     filename: /etc/lua/ratelimit.lua
```

The [lua script](https://github.com/davihsg/tcc/blob/main/envoy/lua/ratelimit.lua) just gets the value from two keys: the spiffe id, and a global key. If either one of them is greater than 0, meaning that there is an ongoing alert, Envoy returns `429 - Too Many Requests` - immediatly. Otherwise, the request is processed normally.

The script works as a time window accumulator that checks the sum of penalty for a SPIFFE ID, and also ongoing problems for the system. First, it removes entries less than `current_time - OFFSET`, then returns the sum of the remaining values. This not only cleans the entries on Redis, but also protects a user from running into a deadlock. Define the `OFFSET` variable with the time you want.

#### 3.3. Set Up Dedicated Alert listener

Add a listener in Envoy that handles alert notifications from OpenSearch. When Envoy receives a notification, it triggers a Lua script to process the alert. This script updates information in the Webdis + Redis container, ensuring that the user's rate limiting or other access control data is adjusted based on the alert.

There are two types of alerts: user alerts and global alerts. User alerts are the ones which were caused because of the user resources, such as `too many requests` and `high request duration sum`. While global alerts are the ones related to global resources, such as `high upstream service cpu usage`.

Each alert has a severity level going from 1 (highest) to 5 (lowest). You can define the penalty for each level on the script `alert.lua`.

Example:
```yaml
listener:
...
- name: alert
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 31415
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
                - name: alert
                  domains: ["*"]
                  routes:
                    - match:
                        path: "/alert"
                        headers:
                          name: ":method"
                          string_match:
                            exact: "POST"
                      direct_response:
                        status: 200
                        body:
                          inline_string: "alerts processed"
            http_filters:
              - name: envoy.filters.http.lua
                typed_config:
                  "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
                  default_source_code:
                    filename: /etc/lua/alert.lua
              - name: envoy.filters.http.router
                typed_config:
                  "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
```

Additionally, the script updates OpenSearch for auditing purposes, maintaining a record of the alerts. To support this functionality, both the Webdis cluster and the OpenSearch cluster must be created and configured. There is a built-in index for alerts on opensearch, but it requires admin privelege to access it, so creating a new one is more simple and gives you more flexibility, like creating a bucket monitor for `alerts per user`.

```yaml
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
- name: opensearch
  connect_timeout: 0.25s
  type: STRICT_DNS
  transport_socket:
    name: envoy.transport_sockets.tls
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
      sni: opensearch
  load_assignment:
    cluster_name: opensearch
    endpoints:
      - lb_endpoints:
          - endpoint:
              address:
                socket_address:
                  address: opensearch
                  port_value: 9200
```

### 4. Set Up OpenSearch

#### 4.1. Create an Index for Envoy Access Logs

You need to create a mapping in OpenSearch for storing Envoy’s access logs. This index will be the same set up in Fluent Bit. 

You can create the index and its mapping using a `curl` command, or by refreshing the current index. Check [envoy_mapping.json](https://github.com/davihsg/tcc/tree/main/opensearch/envoy_mapping.json).

Example `curl` command for creating an index:
```bash
curl --cacert certs/ca.crt -X PUT "http://opensearch:9200/envoy" -H 'Content-Type: application/json' -d'
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

#### 4.2. Create an Index for Alerts

This index will store alert documents sent by the Envoy for further analysis.

You can create the index and its mapping using a `curl` command, or by refreshing the current index. Check [envoy-alerts_mapping.json](https://github.com/davihsg/tcc/tree/main/opensearch/envoy-alerts_mapping.json).

Example `curl` command:
```bash
curl --cacert certs/ca.crt -X PUT "http://opensearch:9200/envoy_alerts" -H 'Content-Type: application/json' -d'
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

#### 4.3. Create a Custom Webhook Channel

Set up a custom webhook in OpenSearch to communicate with the Envoy.

The webhook should be configured with the Envoy URL. It should like this:

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
     "url": "http://envoy:31415/alert",
     "header_params": {
       "Content-Type": "application/json"
     },
     "method": "POST"
   }
 }
}
```

#### 4.4. Create Monitors and Triggers

1. Monitors

    In OpenSearch, create monitors to watch the logs and generate alerts based on specific conditions.

    The index mappings may have nested fields, especially the keyword ones. Opensearch Dashboards UI has problems when showing the group by options because of it, so the monitor should be created using `extraction query` or `via curl`. Here is an [example](https://github.com/davihsg/tcc/tree/main/opensearch/monitors/sum_duration_monitor.json) of how it should look like.

    There are two primary types of monitors: bucket and query monitors. With bucket ones, you can aggregate metrics based on a key and an alert will be triggered for each key. With query ones, you can specific a query and an alert will be triggered based on a defined threshold.

2. Triggers

    Create triggers for the monitors. Documentation is quite scarce in this area, so you should opt to create them using an `extraction query` or via `curl`. Here is an [example](https://github.com/davihsg/tcc/tree/main/opensearch/monitors/trigger_condition.json) of how its condition should look like.

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

    Add actions to the triggers that will send a JSON message with alert details when new alerts are generated or completed. This message will be sent via the webhook channel you configured earlier. The actions must be `Per Query`.

    Even though you can set the custom webhook to send an HTTP request with `Content-Type: application/json`, OpenSearch just the text from the message, so you must set the json yourself.

    Example trigger alert message for bucket monitors:
    ```mustache
    {
     "alerts": [
       {{#ctx.newAlerts}}
       {
         "type" : "bucket",
         "key": "{{bucket_keys}}",
         "monitor_name": "{{ctx.monitor.name}}",
         "trigger_name": "{{ctx.trigger.name}}",
         "trigger_severity": {{ctx.trigger.severity}},
         "period_start": "{{ctx.periodStart}}",
         "period_end": "{{ctx.periodEnd}}",
         "global_scope": false
       },
       {{/ctx.newAlerts}}
       {{#ctx.dedupedAlerts}}
       {
         "type" : "bucket",
         "key": "{{bucket_keys}}",
         "monitor_name": "{{ctx.monitor.name}}",
         "trigger_name": "{{ctx.trigger.name}}",
         "trigger_severity": {{ctx.trigger.severity}},
         "period_start": "{{ctx.periodStart}}",
         "period_end": "{{ctx.periodEnd}}",
         "global_scope": false
       },
       {{/ctx.dedupedAlerts}}
       null
     ]
    }
    ```

### 5. Accessing the API

The rate limiting is now set up. Users can access the API through Envoy by passing the appropriate SVID certificate with their requests.

Example request:
```bash
spire-agent api fetch x509 -write .
curl --cacert bundle.0.pem --cert svid.0.pem --key svid.0.key "https://localhost:10002/items" -k
```

Curl doesn't support HTTPS where the upstream certificate doesn't have CommonName, and SPIRE certificates only have Country, Organization and Serial Number fields. Therefore, the flag `-k` should be passed to `curl`.

## Authors

- [davihsg](https://github.com/davihsg)
