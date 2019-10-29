# Connecting a Namespace to a Registry

An imagePullSecret enables a namespace (and all the deployments in it) to pull container images from a registry.

## GCR to DigitalOcean cluster

1. In the GCP project containing the GCR Registry, Create an IAM Service Account with `Storage Object Viewer` role.

2. Download a JSON private key from the Service Account. Then create a `docker-registry` secret from it on the cluster namespace.

```bash
ns=polite
sakey=k8s-cicd-251209-7a07dcbd9949.json
kubectl -n $ns create secret docker-registry gcr \
--docker-server=gcr.io \
--docker-username=_json_key \
--docker-password="`cat $sakey`" \
--docker-email=any@example.com
```

3. Add the secret to the default Service Account of the namespace.

```bash
ns=polite
kubectl -n $ns patch sa default \
    -p '{"imagePullSecrets": [{"name": "gcr"}]}'
```