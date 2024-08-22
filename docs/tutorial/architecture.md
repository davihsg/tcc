# Architecture Overview

![architecture](https://github.com/davihsg/tcc/raw/main/assets/architecture.png)

## 1. User → Spire Agent
The user must be authenticated in order to communicate with Envoy and the API. So, the first step is to get its SVID from the SPIRE server through the SPIRE Agent.

## 2. User → Envoy
With the SVID, the user can now communicate with API by sending an HTTPS request to Envoy.

## 3. Envoy → Spire Agent
Before stablishing the TLS connection, Envoy validates the user SVID with the SPIRE Agent.

## 4. Envoy → Lua → Opensearch
Envoy has support for running lua scripts on runtime as an HTTP filter before routing the request to the upstream service. So, on our model, Envoy runs a lua script that fetches Opensearch to get information about whether or not the user has exceeded a limit.

If the user has exceeded a limit, then the script returns 429(Too Many Requests) immediately. Otherwise, the request is processed normally.

## 5. Envoy → API
Once the user has not reached a limit, the request is forwarded to the API, and its response is returned to the user normally.

## 6. Envoy → Fluentbit → Opensearch
Envoy container logs are being collected by Fluent Bit, which then processes and sends them to Opensearch.
