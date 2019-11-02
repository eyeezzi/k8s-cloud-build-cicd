# Traefik 2.0

Kubernetes Ingress Controller

## Installation

```bash
kubectl apply -f tfk-crds.yaml tfk-rbac.yaml tfk-deployment.yaml

# Optionally, deploy a test app
kubectl apply -f whoami.yaml
```

NOTE:
Create a *CAA Record* pointing to Letsencrypt for the domain you wish to provision certs for. Because this setup uses TLS-ALPN-01 challenge.

## References

- https://docs.traefik.io/user-guides/crd-acme/