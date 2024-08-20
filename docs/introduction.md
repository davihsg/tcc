# Introduction

In the rapidly evolving context of distributed systems, secure and efficient service communication is crucial. As distributed systems become more and more complex, ensuring secure, authenticated, and observable service interactions presents a significant challenge for tradicional approaches. This thesis explores the integration of three powerful technologies - Envoy, SPIRE, and Opensearch - to address the challenge of access control on these dynamic systems.

## Envoy

Envoy is an open-source L7 proxy designed for large modern service oriented architectures [[1](#references-1)]. Envoy was created to make the network transparent to the applications, and to help developers trace errors faster by having another component dealing with the network concert out of the application stack [[1](#references-1)].

## SPIFFE and SPIRE

SPIFFE (the Secure Production Identity Framework For Everyone) is a set of open-source standards for securely identifying software systems in dynamic environments. With SPIFFE, services and wordloads can assume identities - short lived cryptographic identity documents called SVID - to communicate with others services and workloads via a simple API [[2](#references-2)].

SPIRE (the SPIFFE Runtime Environment) is a implementation of SPIFFE APIs, which performs node and wordload attestation to securely issue and to verify SVIDs [[3](#references-3)]. This integration ensures that every service within the mesh can be authenticated and authorized securely, thereby mitigating the risks associated with unauthorized access.

## OpenSearch

OpenSearch is an open-source search-engine forked from the ElasticSearch service [[4](#references-4)]. OpenSearch is flexible and scalable for data-intensive applications [[5](#references-5)]. By utilizing OpenSearch, organizations can aggregate, visualize, and analyze logs, facilitating real-time insights into the behavior and performance of their services.

## Objective

The objective of this thesis is to demonstrate how combining Envoy, SPIRE, and OpenSearch can create a secure and observable dynamic access control. 

## References

1. <a name="references-1"/> https://www.envoyproxy.io/docs/envoy/v1.31.0/intro/what_is_envoy
2. <a name="references-2"/> https://spiffe.io/docs/latest/spiffe-about/overview
3. <a name="references-3"/> https://spiffe.io/docs/latest/spire-about/spire-concepts
4. <a name="references-4"/> https://en.wikipedia.org/wiki/OpenSearch_(software)
5. <a name="references-5"/> https://opensearch.org/docs/latest/getting-started/intro
