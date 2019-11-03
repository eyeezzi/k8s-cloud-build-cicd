# Configure the DigitalOcean Provider
variable "do_token" {}
// variable "gitlab_token" {}

provider "digitalocean" {
  # token will be obtained from environment variable
  token = var.do_token
}

provider "google" {
  credentials = file("./credentials/google-service-account.json")
  project     = "k8s-cicd-251209"
}

provider "google-beta" {
  credentials = file("./credentials/google-service-account.json")
}

terraform {
  backend "gcs" {
    bucket      = "terraform-state-4e60ea1a1007"
    prefix      = "terraform/state"
    credentials = "./credentials/google-service-account.json"
  }
}
