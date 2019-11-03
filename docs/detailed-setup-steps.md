## Project steps

1. Setup an app with unit tests.
    - Our app will be called *Polite*. It says a greeting when accessed.
2. Setup Google Cloud Storage bucket in TF
    - Set the bucket as the TF storage backend
    - `terraform init` to migrate local state to the bucket.
    - Cleanup the local .tfstate and backup files
3. Create a gitlab repo and connect it to terraform
    - [manual] Add an SSH Key to authenticate your local computer with your Gitlab repo
      - [instructions](https://docs.gitlab.com/ee/ssh/README.html#adding-an-ssh-key-to-your-gitlab-account)
    - Create a Personal Access Token and save it in the envar `GITLAB_TOKEN=<token>`
    - Add the gitlab provider to Terraform
    - Create a `gitlab_project` with TF
    - Generate a keypair with `tls_private_key` in TF
    - Create a `gitlab_deploy_key` with the public key of the generated keypair
    - Encrypt the private key and save it in Google Cloud KMS
        - Create 2 KeyRings for production and staging environments.
            - We'll keep things simple and use just one KeyRing
            - Issue: The KeyRing creation failed with description: "Invalid JWT: Token must be short-lived..."
            - Resolution: Resynced my macbook clock as mentioned [here](https://stackoverflow.com/a/36201957)
        - Create a CryptoKey for in each KeyRing. This will be used to encrypt and decrypt secrets.
            - Issue: the KeyRing
        - Encrypt the private key with the cryptokey.
        - Cloud build agents will need to decrypt the private key using this cryptokey, inorder access our repo via SSH.
    - Create Google Cloud Build Triggers that run the pipeline steps when changes are commited to the repo
      - DRAWBACK: GCB does not offer a way to programatically or via UI link GCB to a Gitlab Repo. Although it allows you to link a Github and Bitbucket repo via the UI only.
      - DRAWBACK (UNTESTED): One alternative to link Gitlab Repo to GCP is to deploy a Cloud Function which will be called from Gitlab as a webhook whenever a repo event happens. This is just another complicated and unnecessary component to manage.
      - Cloud Build can connect to Github in 2 ways: by mirroring a repository in Cloud Sources or by installing the Cloud Build Github App on the Github repository as an integration. The latter is recommended because it supports triggering builds from pull request changes.
      - (Discouraged) Manually setup a cloud source repo that mirrors the gitlab repo. Then create cloud build triggers off the cloud source mirror.
        - Create a Cloud Source Repository (TF)
        - Generate credentials for the CSR (manual)
        - Use Cloud Shell to setup the repo URL, Username, and Password.
        - In Gitlab, setup a mirror to your repo using the CSR URL, Username, and Password.
        - Commit a dummy file to your Gitlab repo and confirm it appears in CSR.
        - [instructions](https://cloud.google.com/solutions/mirroring-gitlab-repositories-to-cloud-source-repositories)
        - DRAWBACKS:
          - Painfully manual process.
          - Syncing starts after an unpredictable delay.
      - [TF] Create a Cloub Build Trigger (CBT) for 'dev' branches, connected to the CSR and targeting any
        - Supported Envars on cloudbuild.yaml files: $PROJECT_ID, $REPO_NAME, $BRANCH_NAME, $TAG_NAME, $COMMIT_SHA, $SHORT_SHA
4. Create a K8s cluster on DigitalOcean.
    - Drawback: You cannot create a DO project in TF and associate it with a DO cluster. (unsure where I needed this ability)
    - Sign/Signup and create a Project.
    - Create a *DO API token* and configure Terraform to use it.
        - Home > Manage > API > Generate New Token > Copy
        - Set environment variable `DIGITALOCEAN_TOKEN=<token>` on your local machine.
        - `terraform init` in `iac/`
    - Drawback: DO does not support assigning a public static IP (floating IP) to a load balancer.
    - Issue: cluster `node_pool` is actually a list, but not documented as such.
    - Create a load balancer that fronts the cluster's node_pool.
        - Issue: You cannot pass a list of the cluster's nodes to the lb like so `<cluster>.<name>.node_pool[0].nodes[0].id`. This gives a UUID, but DO expects an integer.
            - Workaround: tag the nodes in the node_pool and specify the tag in the LB
    - Enable the cluster to pull images from GCR
        - Create a google service account
        - Grant the service account "roles/storage.objectViewer" role
        - Create a service account key
        - Create a K8s ImagePullSecret with this key
            - Requires that you have the TF K8s Provider, connected to the cluster.
            - DRAWBACK: manual step. The Terraform Kubernetes Provider has a bug that prevents proper encoding at the moment.
        - Drawback: DO does not provide a K8s exploration dashboard like GKE to view container logs etc.
5. Point a domain name to your cluster LB, i.e MY_DOMAN=polite.opsolute.com -> DO K8s LB IP
    - Buy a domain name with a registrar like Namecheap (manual)
    - Point your domain to the Digitalocean nameservers by adding the NS records to your Registrars account: `ns1.digitalocean.com.`, `ns2.digitalocean.com.`, `ns3.digitalocean.com.` [ref](https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars)
        - TODO: Use a registrar where NS records can be provisioned by Terraform.
    - Create a Domain (aka managed zone) for MY_DOMAIN
        - TODO: parameterize this, so the domain can be passed into terraform as an argument.
        - Verify MY_DOMAIN points to cluster LB using `dig +short MY_DOMAIN`
    - Add a CNAME records for the staging environment.
        - staging.MY_DOMAIN -> IP of Cluster LB
        - The raw domain without the 'staging' prefix will point to the production environment
        - Notice that both endpoints point to the same Load balancer IP. We will do the traffic-splitting in software.
6. Create a GCP Project and connect it to Terraform
    - Enable the following APIs for the project.
        - Cloud Build API
        - Cloud Key Management API
        - Container Registry API
        - Identity and Access Management (IAM) API
        - Cloud Resource Manager API
        - Cloud Source Repositories API (enabled by default)
    - Create a Service Account, with editor privilege, download the svc acct key and provide it to TF
    - The project automatically gets a GCR registry at gcr.io/PROJECT_ID [REF](https://stackoverflow.com/questions/53714284/how-do-you-create-a-gcr-repo-with-terraform)
    - Drawback: you cannot use the Github Terraform Provider for Individual accounts [ref](https://github.com/terraform-providers/terraform-provider-github/issues/45)
    - Build and push app image to GCR
        - Set gcloud as docker auth provider
        - Build image with gcr-format tag
        - Push image.
            - Use full image gcr URL in deployment yaml
            - Apply deployment in DigitalOcean cluster
7. Deploy Traefik Ingress Controller to K8s Cluster
   1. Use the Terraform "helm" provider
      1. This provider will install Tiller to a namespace in the cluster
      2. If RBAC is enabled in the cluster (default case), then Tiller needs a servie account with enough privilege to install helm chart components. By default Tiller uses the default service account in the namespace it is deployed.
      3. Create a ServiceAccount (in tiller's namespace), and give it a 'cluster-admin' role via a ClusterRoleBinding. Then configure the helm provider to use this ServiceAccount for Tiller.
         1. TODO: currently manual...create ServiceAccount and ClusterRoleBinding with TF Kubernetes Provider.
         2. TODO: reduce Tiller's access. I dislike the idea of giving Tiller cluster-admin privilege.
         3. REF: https://helm.sh/docs/rbac/#role-based-access-control


