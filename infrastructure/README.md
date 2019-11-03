# CI/CD Infrastructure as Code

Provisions the following infrastructure:

1. Staging and Production K8s clusters on DigitalOcean.
2. DNS Records on DigitalOcean
3. Service Accounts on GCP

## Prerequisite

- Terraform v0.12.7
- Set the environment variable `DIGITALOCEAN_TOKEN=<personal access token>`

## Terraform Commands

```bash
LOGFILE="terraform.log"; \
export TF_LOG=DEBUG; \
export TF_LOG_PATH=$LOGFILE; \
rm $LOGFILE; \
terraform plan \
-var "do_token=${DIGITALOCEAN_TOKEN}"

terraform apply \
-var "do_token=${DIGITALOCEAN_TOKEN}" \
-auto-approve

terraform destroy \
-var "do_token=${DIGITALOCEAN_TOKEN}" \
-auto-approve

# plan/apply/destroy a specific resource
terraform plan -target RESOURCE.NAME -out run.plan
terraform destroy -target RESOURCE.NAME -out run.plan

terraform apply run.plan

# show the graph resource dependencies
terraform graph -type=plan -draw-cycles | dot -Tpng > graph.png
```

## Helpful tools

1. VSCode 'Terraform' extension by Mikael Olenfalk
   1. Turn on format on save.
   2. Enable the language server for TF 0.12 support.
   3. Install tflint (This doesn't seem to help linting.)
2. 'Terraform doc snippets' by Run at Scale TODO

## Lessons Learnt

### Resource dependency can lead to error during `terraform destroy`

#### Case

- `helm_release.traefiker` depends on the `provider.helm` which depends on `kubernetes_service_account.tiller`. There is also a `kubernetes_cluster_role_binding.tiller`  which gives the svc account permissions.
- When deleting `helm_release.traefiker`, TF does not know that the cluster_role_binding should not be deleted before the helm release otherwise tiller would not have the access to do the deletion.

#### Solution

- Add an explicit dependency on the resource. In this case, add the property `depends_on = [kubernetes_cluster_role_binding.tiller]` to the `helm_release.traefiker`.

- Graph the new resource dependency to see that the `helm_release.traefiker` now depends on both the `kubernetes_service_account.tiller` and `kubernetes_cluster_role_binding.tiller`.

#### Lesson

- To verify your resource setup and teardown is seamless, apply with terraform and *targeted-destroy* with terraform. Some implicit dependency issues only show-up when you destroy the resource.

### TODO: Use case for terraform taint

- `terraform taint RESOURCE.NAME` marks the resource for recreation on the next apply.

### Terraform command timeout

Running a command like `terraform plan` hangs, then times out after 5-10 minutes, with the error

```**bash******
Error: timeout while waiting for state to become 'Running' (last state: 'Pending', timeout: 5m0s)
```

#### Diagnosis

This issue was caused by a dependency chain waiting for a resource that never got created. The *root* module was waiting for the *helm* provider which was waiting for *helm_release.traefik* which never got created.

#### Fix

Manually deleted the pending resource.

```bash
# view the resources in the TF state
terraform state list
# remove the waiting resource
terraform state rm helm_release.traefik
```

#### Debugging

Enabled logs when running terraform. The dependency loop is visible in the last lines of logs.

```bash
LOGFILE="terraform.log"; \
export TF_LOG=DEBUG; \
export TF_LOG_PATH=$LOGFILE; \
rm $LOGFILE; \
terraform plan
```

```log
# terraform.log
...
2019/09/05 20:06:47 [TRACE] dag/walk: vertex "provider.helm (close)" is waiting for "helm_release.traefik"
2019/09/05 20:06:49 [TRACE] dag/walk: vertex "root" is waiting for "provider.helm (close)"
...
2019/09/05 20:06:52 [TRACE] dag/walk: vertex "provider.helm (close)" is waiting for "helm_release.traefik"
2019/09/05 20:06:54 [TRACE] dag/walk: vertex "root" is waiting for "provider.helm (close)"
2019/09/05 20:06:57 [TRACE] dag/walk: vertex "provider.helm (close)" is waiting for "helm_release.traefik"
```

### Helm Provider is too buggy

The helm provider is imature for production usage because of the following reasons:

- The helm provider installs tiller in the cluster, yet it requires pre-creation of a service-account with cluster-role-binding for tiller to work.

- The helm provider will only install the tiller deployment when a helm_release is created, this is unexpected and confusing.

- helm_release resource sometimes does not install specified chart.

- helm_release resource does not report status when real state of chart components diverge from that specified in TF

- It is not clear what exactly you're installing from the chart.

### DigitalOcean Kubernetes does not support reusing LoadBalancer IP

Every Loadbalancer-type service creates a new Network Loadbalancer in DigitalOcean. Even when you set the `loadbalancerip` of the service to an existing loadbalancer, DO still creates a new LB with its own IP, hence the service's external IP keeps changing with each modification. This is obviously not ideal for production because you'd need to change yor DNS records to point to the new IP every time.

This is a major flaw of DO, and there seems to be no fix in sight.

The workaround for now is to manually provision a new DNS record that points to the service's LB IP...after the service has been created. You cannot do this automatically, because there's no way of getting a k8s service's external IP in terraform WHEN THE SERVICE WAS CREATED WITH THE HELM PROVIDER.


## Import external resource into TF

```sh
terraform import -var "gitlab_token=${GITLAB_TOKEN}" \
google_sourcerepo_repository.github-mirror github_eyeezzi_k8s-cloud-build-cicd
```