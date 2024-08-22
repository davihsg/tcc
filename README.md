![opensearch+envoy](https://github.com/davihsg/tcc/raw/main/assets/opensearch+envoy.png)
# Opensearch and Envoy

This repository presents a simple, yet sophisticated, implementation of access control using Envoy Proxy and Opensearch.

## Architecture

The architecture assumes that Envoy logs are being sent to Opensearch under the index `envoy`. If not, you can check this example.

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

6. **Alert Handling and Database Update:**  
   The Alerting API processes the notification and updates the relevant information in the Redis database. To update the Redis database, the API sends an HTTPS request to Envoy, which downgrades the connection from HTTPS to HTTP and forwards the request to Webdis. Envoy acts as a reverse proxy in this scenario.

This flow ensures secure access, request rate limiting, logging, and monitoring with automatic updates based on alerts.

## Authors

- [davihsg](https://github.com/davihsg)
