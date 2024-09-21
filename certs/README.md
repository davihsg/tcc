# Certs

To ensure secure communication between components, TLS is implemented where necessary. Therefore, the certificates for the CA and other components must be created beforehand. We will walk through each step.

## Prerequisites

Before you begin, ensure you have `openssl` installed. If not, install it using:

```bash
sudo apt-get update
sudo apt-get install openssl
```

Verify the installation with:

```bash
openssl version
```

Then, navigate to this directory:

```bash
cd certs
```

## 1. Create the Certificate Authority (CA)

### 1.1. Generate the CA Private Key

Create a private key for the CA:

```bash
openssl ecparam -genkey -name prime256v1 -noout -out ca.key
```

### 1.2. Create the CA Self-Signed Certificate

Generate a self-signed certificate for the CA:

```bash
openssl req -x509 -new -key ca.key -sha256 -days 3650 -out ca.crt -config ca.cnf
```

The **Common Name (CN)** field will be used as the trusted domain throughout the entire system. In this example, we will use `dhsg.com`, but feel free to change it to your domain on `ca.cnf`. 

Ensure the certificate was created correctly:

```bash
openssl x509 -in ca.crt -text -noout
```

## 2. Create a Certificate for OpenSearch

### 2.1. Generate the Private Key for OpenSearch

```bash
openssl genrsa -out opensearch.key 4096
```

### 2.2. Create the CSR (Certificate Signing Request)

See `opensearch.cnf` file before creating the CSR, and change where is needed.

```bash
openssl req -new -key opensearch.key -out opensearch.csr -config opensearch.cnf
```

### 2.3. Sign the CSR with the CA

```bash
openssl x509 -req -in opensearch.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out opensearch.crt -days 365 -sha256 -extensions v3_req -extfile opensearch.cnf
```

Ensure the certificate was created correctly:

```bash
openssl x509 -in ca.crt -text -noout
```
