resource "digitalocean_kubernetes_cluster" "hive-staging" {
  name    = "hive-staging"
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

# Point all subdomains to the traefik loadbalancer IP
#   staging.app-1.myorg.com
#   staging.app-n.myorg.com     ----> 5.5.5.5 (traefik service)
# NOTE: 
#   DigitalOcean always provisions a new LoadBalancer for a loadbalancer-type K8s service.
#   This new LB has a new IP, and you cannot preset the IP through the service definition (like in GKE).
#   So whenever the traefik service LB IP changes, YOU MUST update this record accordingly.
# ISSUE:
#   - https://www.digitalocean.com/community/questions/how-to-set-static-ip-for-loadbalancer-in-kubernetes
#   - https://www.digitalocean.com/community/questions/how-to-reuse-do-loadbalancer-previously-created-through-kubernetes
resource "digitalocean_record" "wildcard-polite-opsolute-com" {
  domain = digitalocean_domain.polite-opsolute-com.name
  type   = "A"
  name   = "*"
  value  = "45.55.106.142"
}
