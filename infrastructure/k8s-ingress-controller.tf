provider "helm" {
  kubernetes {
    host                   = digitalocean_kubernetes_cluster.hive.endpoint
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.hive.kube_config.0.cluster_ca_certificate)
    client_key             = base64decode(digitalocean_kubernetes_cluster.hive.kube_config.0.client_key)
    client_certificate     = base64decode(digitalocean_kubernetes_cluster.hive.kube_config.0.client_certificate)
  }
  namespace       = kubernetes_service_account.tiller.metadata.0.namespace
  service_account = kubernetes_service_account.tiller.metadata.0.name # Tiller will use this SA. Must already exist.
  tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.11.0"
  install_tiller  = true
}

# I like the ability to delete every tiller component by deleting the namespace.
resource "kubernetes_namespace" "tiller" {
  metadata {
    name = "tiller"
  }
}

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = kubernetes_namespace.tiller.metadata.0.name
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller"
  }

  # TODO: reduce this broad access.
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  # api_group has to be empty because of a bug:
  # https://github.com/terraform-providers/terraform-provider-kubernetes/issues/204
  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller.metadata.0.name
    namespace = kubernetes_service_account.tiller.metadata.0.namespace
  }
}

# ISSUE: helm provider only creates tiller deployment when a helm_release resource is created
# see: https://github.com/terraform-providers/terraform-provider-helm/issues/148#issuecomment-474616099
resource "helm_release" "traefiker" {
  name      = "traefik"
  chart     = "stable/traefik"
  version   = "1.77.1"
  namespace = "tiller"

  set {
    name  = "serviceType"
    value = "LoadBalancer"
  }

  # basically no-op for DigitalOcean
  // set {
  //   name  = "loadBalancerIP"
  //   value = digitalocean_loadbalancer.public.ip
  // }

  set {
    name  = "rbac.enabled"
    value = true
  }

  depends_on = [kubernetes_cluster_role_binding.tiller]
}

# Point all subdomains to the traefik loadbalancer IP
#   staging.example.com  --\
#   test.example.com     ----> 5.5.5.5 (traefik service)
#   anything.example.com --/
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
