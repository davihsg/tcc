![opensearch+envoy](https://github.com/davihsg/tcc/raw/main/assets/opensearch+envoy.png)
# Opensearch and Envoy

This repository presents a simple, yet sophisticated, implementation of access control using Envoy Proxy and Opensearch aligned with a Secret Discovery Service (SDS), in this case, SPIRE.

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
