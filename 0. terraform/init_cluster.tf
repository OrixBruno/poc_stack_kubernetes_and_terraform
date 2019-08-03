provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_kubernetes_cluster" "foo" {
  name    = "k8s-cluster-nyc1-1-14-1-do-4"
  region  = "nyc1"
  version = "1.14.1-do.4"

  node_pool {
    name       = "pool-initial"
    size       = "s-1vcpu-2gb"
    node_count = 2
  }
}