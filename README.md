# Opensearch and Envoy

This repository presents a simple, yet sophisticated, implementation of access control using Envoy Proxy and Opensearch aligned with a Secret Discovery Service (SDS), in this case, SPIRE.

## Motivation

Envoy is an open-source L7 proxy created to make the network transparent for the applications, and to help developers trace errors by having another component dealing with the network concern.
One of its features is Rate Limiting. Envoy has three types of rate limiting implementations:

- [Local](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/local_rate_limiting): HTTP rate limiting for one Envoy instance;

- [Global](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting): HTTP rate limiting for multiple Envoy instances integrated with a global gRPC rate limiting service;

- [Quota](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting#quota-based-rate-limiting): Quota based is an extension of global rating limiting which periodically loads reports to a global gRPC service. It is currently a work in progress feature.

Even though you can implement your own gRPC rate limiting service, the proto tree is very extensive, and Envoy's [reference implementation](https://github.com/envoyproxy/ratelimit) only supports requests per unit of time, which isn't ideal for highly sensitive data systems.

That's when Opensearch comes in. Opensearch is an open-source engine for data visualization, such as search, aggregation, and audit logging. Such a powerful tool is very often integrated with many systems because of its data processing capabilities, so why not use it for access control?

With Envoy controlling all the network flow, we can easily ingest its logs into Opensearch and implement our own rate limiting service.

## Architecture Overview

![architecture](https://github.com/davihsg/tcc/raw/main/assets/architecture.png)

### 1. User → Spire Agent
The user must be authenticated in order to communicate with Envoy and the API. So, the first step is to get its SVID from the SPIRE server through the SPIRE Agent.

### 2. User → Envoy
With the SVID, the user can now communicate with API by sending an HTTPS request to Envoy.

### 3. Envoy → Spire Agent
Before stablishing the TLS connection, Envoy validates the user SVID with the SPIRE Agent.

### 4. Envoy → Lua → Opensearch
Envoy has support for running lua scripts on runtime as an HTTP filter before routing the request to the upstream service. So, on our model, Envoy runs a lua script that fetches Opensearch to get information about whether or not the user has exceeded a limit.

If the user has exceeded a limit, then the script returns 429(Too Many Requests) immediately. Otherwise, the request is processed normally.

### 5. Envoy → API
Once the user has not reached a limit, the request is forwarded to the API, and its response is returned to the user normally.

### 6. Envoy → Fluentbit → Opensearch
Envoy container logs are being collected by Fluent Bit, which then processes and sends them to Opensearch.

## Running

We are using docker to manage the network between services since it provides a simple DNS server that makes the communication a lot easier. Only the SDS server, SPIRE, won't be running on docker.

### Setup

To start this example, first clone the current repository:

```bash
$ git clone https://github.com/davihsg/tcc.git
```

### SPIRE

SPIRE is going to be the SDS. SPIRE performs node and wordload attestation to issue, and to verify SVIDs - short lived cryptographic identity documents. It has a great integration with Envoy, and if you want to use another SDS, you will have to update Envoy's configuration.

In order to run this example, the spire-agent must be running on the same machine as the envoy container. Check [here](https://github.com/davihsg/tcc/tree/main/spire#readme) how to setup a development SPIRE environment.

### Opensearch

### Fluent Bit

### Envoy

## Authors

- [davihsg](https://github.com/davihsg)
