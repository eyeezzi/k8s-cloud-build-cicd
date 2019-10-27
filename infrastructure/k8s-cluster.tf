resource "digitalocean_kubernetes_cluster" "hive-staging" {
  name    = "hive"
  region  = "nyc1"
  version = "1.15.5-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 2
    tags       = ["bees"]
  }
}

resource "digitalocean_kubernetes_cluster" "hive-prod" {
  name    = "hive-prod"
  region  = "nyc1"
  version = "1.15.5-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 2
    tags       = ["bees"]
  }
}

# Point the naked domain to the cluster load balancer. This will be our production endpoint.
resource "digitalocean_domain" "polite-opsolute-com" {
  name = "polite.opsolute.com"
  // ip_address = digitalocean_loadbalancer.public.ip
}

/*
# Deprecate for now
# Because a LoadBalancer is useless for kubernetes in DigitalOcean.

# DO Load Balancers are network LBs, not Application LBs.
# This means they only distribute traffic to droplets, not to applications based on URLs or HTTP headers.
# Drawback: The IP of a LB is generated, you cannot assign an IP.
resource "digitalocean_loadbalancer" "public" {
  name   = "loadbalancer-1"
  region = digitalocean_kubernetes_cluster.hive.region

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_tag = tolist(digitalocean_kubernetes_cluster.hive.node_pool[0].tags)[0]
}

# Create a staging endpoint.
resource "digitalocean_record" "staging-polite-opsolute-com" {
  domain = digitalocean_domain.polite-opsolute-com.name
  type   = "CNAME"
  name   = "staging"
  value  = "${digitalocean_domain.polite-opsolute-com.name}."
}
*/

# A Floating IP is an publicly-accessible Static IPv4 address
# It cannot be assigned to a K8s worker node.
// resource "digitalocean_floating_ip" "foobar" {
//   droplet_id = "${digitalocean_droplet.foobar.id}"
//   region     = "${digitalocean_kubernetes_cluster.hive.region}"
// }

# @inconvenience: the local gcloud has to be authenticated with the project.

# Save the kubeconfig file to access the cluster.
# Encrypt it with the Google KMS key
resource "local_file" "kubeconfig" {
  sensitive_content = digitalocean_kubernetes_cluster.hive.kube_config.0.raw_config
  filename          = "../secrets/kubeconfig.enc"

  provisioner "local-exec" {
    command = "echo $KUBECONFIG | gcloud kms encrypt --project=k8s-cicd-251209 --plaintext-file=- --ciphertext-file=- --location=global --keyring=${google_kms_key_ring.polite-staging.name} --key=${google_kms_crypto_key.polite-staging-default.name} | base64 > ${self.filename}"
    environment = {
      KUBECONFIG = "${self.sensitive_content}"
    }
  }
}

# Allow the DigitalOcean cluster to pull images from the Google Container Registry.
# A GCP Project has 1 GCR Registry per region, which is backed by a GCS Bucket.
# You grant access to the registry by granting access to its underlying storage bucket.

resource "google_service_account" "digital-ocean-cluster" {
  account_id   = "digital-ocean-cluster"
  display_name = "digital-ocean-cluster"
}

# Grant the service account read access to buckets in the entire GCP project.
# Unlike access to an individual storage bucket, this does not require pushing an image first.
# NOTE: possible roles = roles/storage.admin, roles/storage.objectViewer
resource "google_project_iam_member" "digital-ocean-cluster" {
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.digital-ocean-cluster.email}"
}

resource "google_service_account_key" "digital-ocean-cluster" {
  service_account_id = google_service_account.digital-ocean-cluster.name
}

# Create 2 Virtual Clusters to represent the 2 deployment environments: Staging and Production
// resource "kubernetes_namespace" "polite" {
//   metadata {
//     name = "staging"
//   }
// }

// resource "kubernetes_namespace" "production" {
//   metadata {
//     name = "production"
//   }
// }

/*----------------------
# TODO (IMPORTANT): Automate the creation of GCR ImagePullSecret.
# For some reason, I cannot create the GCR ImagePullSecret using TF resources.
# So I have created it manually following the instructions here: 
#   - http://docs.heptio.com/content/private-registries/pr-gcr.html
# ISSUE: https://github.com/terraform-providers/terraform-provider-kubernetes/issues/611

# Create an ImagePullSecret from the GCR service account key.
# Specify this ImagePullSecret in every PodSpec that pulls images from GCR
locals {
  dockerconfigjson = {
    "https://gcr.io" = {
      email    = "youremail@example.com" # required but unused
      username = "_json_key"             # must be _json_key
      // password = base64decode(google_service_account_key.digital-ocean-cluster.private_key)
      password = "test"
    }
  }
}
resource "kubernetes_secret" "gcr-imagepullsecret-staging" {
  metadata {
    name      = "gcr-imagepullsecret-staging"
    namespace = kubernetes_namespace.staging.metadata.0.name
  }
  data = {
    ".dockerconfigjson" = jsonencode(local.dockerconfigjson)
  }
  type = "kubernetes.io/dockerconfigjson"
}
output gcr-private-key {
  value = kubernetes_secret.gcr-imagepullsecret-staging.data
}
------------------*/

// TODO: GCR imagePullSecret for production env

# Add imagePullSecret to K8s Deployment template file
// TODO

// # Add the GCR ImagePullSecret to the default ServiceAccount in the Staging Namespace.
// # DRAWBACK: TF cannot edit the default ServiceAccount in a namespace WITHOUT first importing it.
// #   This limitation makes manual intervention a neccessity when deploying infrastructure, so ignore this approach.
// # issue: https://github.com/terraform-providers/terraform-provider-kubernetes/issues/302
// resource "kubernetes_service_account" "default-serviceaccount-staging" {
//   metadata {
//     name = "default"
//     namespace = kubernetes_namespace.staging.metadata.0.name
//   }
//   image_pull_secret {
//     name = kubernetes_secret.gcr-imagepullsecret-staging.metadata.0.name
//   }
// }
