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
}

resource "digitalocean_record" "staging-polite-opsolute-com" {
  domain = digitalocean_domain.polite-opsolute-com.name
  type   = "A"
  name   = "staging"
  value  = "134.209.130.67"
}

resource "digitalocean_record" "prod-polite-opsolute-com" {
  domain = digitalocean_domain.polite-opsolute-com.name
  type   = "A"
  name   = "@"
  value  = "157.230.202.209"
}

# Required for Traefik to use Letsencrypt TLS-ALPN-01 challenge
resource "digitalocean_record" "polite-opsolute-com-caa" {
  domain = digitalocean_domain.polite-opsolute-com.name
  type   = "CAA"
  name   = "@"
  value  = "letsencrypt.org."
  tag    = "issue"
  flags  = 0
}
