# Deployers

A Deployer is a K8s Service Account with the RBAC access to create the main resources required to deploy an application: Deployment, Service, Ingress, etc.

By combining the access token from the Deployer and a KUBECONFIG file, a continous deployment pipeline has all it needs to deploy an application to an environment.

- A Cluster represents an Environment like Staging.
- A Namespace represents an Application.

Therefore there should be one Deployer per Namespace per Cluster.

## Create a kubeconfig file to be used for deployment pipeline

```bash
# 1. Ensure you have access to the cluster.
export KUBECONFIG=/path/to/file
kubectl auth can-i create sa

# 2. Create a deployer. NOOP if deployer already exists.
kubectl apply -f polite-deployer.yaml

# 3. Generate the kubeconfig and access token for the CD pipeline
./gen-access.sh
./gen-access.sh polite deployer hive-prod

# 4. Commit the generated kubeconfig to version control and add
# the token as an environment variable in Cloud Build trigger.
```

## TODO

- Use Kustomize to enable creating deployers for multiple Namespaces from the same base files.
- Also provide Secret for Service Account because it appears K8s does not automatically generate the ServiceAccount secret sometimes.
