# SPIRE

[SPIRE](https://github.com/spiffe/spire) (the [SPIFFE](https://github.com/spiffe/spiffe) Runtime Environment) is a tool-chain for establishing trust between software systems across a wide variety of hosting platforms.

The configuration files included in this release are intended for evaluation
purposes only and are **NOT** production ready.

The example below is intended to be running on Linux. Check [SPIRE's documentation](https://spiffe.io/docs/latest/try/) for other cases.

## Running

## Prerequisites

First of all, install spire on your machine:

```bash
$ curl -s -N -L https://github.com/spiffe/spire/releases/download/v1.10.0/spire-1.10.0-linux-amd64-musl.tar.gz | tar xz
```

Once you have downloaded, add SPIRE binaries to your path:

```bash
$ export PATH="$PATH:$(pwd)/spire-1.10.0/bin"
```

To have binaries accessible on every bash session, add the command above to your `.bashrc` file and restart the session with `source ~/.bashrc`. It is really useful.

Then, navigate to this directory:

```bash
cd spire 
```

## 1. Starting SPIRE Server

Checkout our SPIRE Server configuration [example](https://github.com/davihsg/tcc/blob/main/spire/conf/server/server.conf) before starting the server.

Remember, the trust domain will be the same for all components. This example uses `dhsg.com`, if you are using another one, change it on `server.conf`.

Now, simply run:

```bash
spire-server run -config conf/server/server.conf &
```

Verify the server health:

```bash
spire-server healthcheck
```

## 2. Starting SPIRE Agent

Before running the SPIRE Agent, the server must ensure its identity. To do so, you must create a join token for it:

```bash
$ spire-server token generate -spiffeID spiffe://dhsg.com/agent
Token: <token_string>
```

The SPIRE Agent configuration must have two workload attestations plugins:

- `docker`: for validating Envoy's identity;
- `unix`: for validating the users' identity.

Here is an example of how it should look like:

```
agent {
    data_dir = "./data/agent"
    log_level = "DEBUG"
    trust_domain = "dhsg.com" # trust domain
    server_address = "localhost"
    server_port = 8081

    trust_bundle_path = "../certs/ca.crt" # path to CA bundle
}

plugins {
   KeyManager "disk" {
        plugin_data {
            directory = "./data/agent"
        }
    }

    NodeAttestor "join_token" {
        plugin_data {}
    }

    WorkloadAttestor "docker" {
        plugin_data {}
    }

    WorkloadAttestor "unix" {
        plugin_data {}
    }
}
```

Remember, SPIRE Agent and Server' trust domain must be the same.


Now, just start the SPIRE Agent:

```bash
$ bin/spire-agent run -config conf/agent/agent.conf -joinToken <token_string> &
```

Verify the agent health:

```bash
spire-agent healthcheck
```

## 3. Create registration policies

### 3.1. Envoy

Envoy is identified based on its docker image id.

```bash
spire-server entry create -parentID spiffe://dhsg.com/agent \
    -spiffeID spiffe://dhsg.com/envoy-api -selector docker:image_id:envoyproxy/envoy:contrib-v1.29.1
```

### 3.2. Users

An user is identified based on its unix id.

```bash
spire-server entry create -parentID spiffe://dhsg.com/agent \
    -spiffeID spiffe://dhsg.com/dummy-user -selector unix:uid:$(id -u)
```

The user can fetch its certs by running the command:

```bash
spire-agent api fetch x509 -write .
```

Now it can communicate with Envoy properly.

## Next Steps
