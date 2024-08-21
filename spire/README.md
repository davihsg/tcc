# SPIRE

[SPIRE](https://github.com/spiffe/spire) (the [SPIFFE](https://github.com/spiffe/spiffe) Runtime Environment) is a tool-chain for establishing trust between software systems across a wide variety of hosting platforms.

The configuration files included in this release are intended for evaluation
purposes only and are **NOT** production ready.

The example below is intended to be running on Linux. Check [SPIRE's documentation](https://spiffe.io/docs/latest/try/) for other cases.

## Running

### Installing SPIRE

```bash
$ curl -s -N -L https://github.com/spiffe/spire/releases/download/v1.10.0/spire-1.10.0-linux-amd64-musl.tar.gz | tar xz
```

Once you have downloaded, add SPIRE binaries to your path:

```bash
$ export PATH="$PATH:$HOME/spire-1.10.0/bin"
```

To have binaries accessible on every bash sessions, add the command above to your `.bashrc` file and restart the session with `source ~/.bashrc`. It is really useful.

### Starting SPIRE Server

Checkout our SPIRE Server configuration example [example](https://github.com/davihsg/tcc/blob/main/spire/conf/server/server.conf) before starting the server.

Use the trust domain as you wish, on this example, I am using `dhsg.com`.

```bash
$ spire-server run -config conf/server/server.conf &
```

### Starting SPIRE Agent

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
    trust_domain = "dhsg.com"       # Must be the same as the SPIRE Server one
    server_address = "localhost"    # SPIRE Server address
    server_port = 8081              # SPIRE Server port

    # Insecure bootstrap is NOT appropriate for production use but is ok for 
    # simple testing/evaluation purposes.
    insecure_bootstrap = true
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

Now, just start the SPIRE Agent:

```bash
$ bin/spire-agent run -config conf/agent/agent.conf -joinToken <token_string> &
```

### Create a registration policy for Envoy

Envoy is identified based on its image id.

```bash
spire-server entry create -parentID spiffe://dhsg.com/agent \
    -spiffeID spiffe://dhsg.com/envoy-api -selector docker:image_id:envoyproxy/envoy:contrib-v1.29.1
```

### Create a registration policy for the User

A user is identified based on its unix id.

```bash
spire-server entry create -parentID spiffe://dhsg.com/agent \
    -spiffeID spiffe://dhsg.com/dummy-user -selector unix:uid:$(id -u)
```

### Fetching x509-SVID

The user can fetch its certs by running the command:

```bash
spire-agent api fetch x509 -write .
```

Now it can communicate with Envoy properly.
