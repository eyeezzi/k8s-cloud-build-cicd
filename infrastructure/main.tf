# Configure the DigitalOcean Provider
variable "do_token" {}

provider "digitalocean" {
  # token will be optained from environment variable
  token = var.do_token
}

provider "google" {
  credentials = file("./credentials/google-service-account.json")
  project     = "k8s-cicd-251209"
}

provider "google-beta" {
  credentials = file("./credentials/google-service-account.json")
}

variable "gitlab_token" {}

provider "gitlab" {
  token = "${var.gitlab_token}"
}

terraform {
  backend "gcs" {
    bucket      = "terraform-state-4e60ea1a1007"
    prefix      = "terraform/state"
    credentials = "./credentials/google-service-account.json"
  }
}

# data "digitalocean_kubernetes_cluster" "hive" {
#   name = "hive"
# }

# Using explicit fields from cluster does not work. I had to use the 
# kubeconfig file on the local machine. This involves manual step
# and is inconvenient.

provider "kubernetes" {
  version = "1.9.0"
  # load_config_file = false

  host = digitalocean_kubernetes_cluster.hive.endpoint
  # cluster_ca_certificate = base64decode(data.digitalocean_kubernetes_cluster.hive.kube_config.0.cluster_ca_certificate)

  # client_key         = base64decode(data.digitalocean_kubernetes_cluster.hive.kube_config.0.client_key)
  # client_certificate = base64decode(data.digitalocean_kubernetes_cluster.hive.kube_config.0.client_certificate)

  # token = digitalocean_kubernetes_cluster.hive.kube_config.0.token

  # config_context_auth_info = "do-nyc1-hive-admin"
  # config_context_cluster   = "do-nyc1-hive"
}
