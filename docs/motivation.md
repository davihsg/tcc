# Motivation

Envoy is an open-source L7 proxy created to make the network transparent for the applications, and to help developers trace errors by having another component dealing with the network concern.
One of its features is Rate Limiting. Envoy has three types of rate limiting implementations:

- [Local](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/local_rate_limiting): HTTP rate limiting for one Envoy instance;

- [Global](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting): HTTP rate limiting for multiple Envoy instances integrated with a global gRPC rate limiting service;

- [Quota](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting#quota-based-rate-limiting): Quota based is an extension of global rating limiting which periodically loads reports to a global gRPC service. It is currently a work in progress feature.

Even though you can implement your own gRPC rate limiting service, the proto tree is very extensive, and Envoy's [reference implementation](https://github.com/envoyproxy/ratelimit) only supports requests per unit of time, which isn't ideal for highly sensitive data systems.

That's when Opensearch comes in. Opensearch is an open-source engine for data visualization, such as search, aggregation, and audit logging. Such a powerful tool is very often integrated with many systems because of its data processing capabilities, so why not use it for access control?

With Envoy controlling all the network flow, we can easily ingest its logs into Opensearch and implement our own rate limiting service.