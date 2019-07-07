variable "GOOGLE_PROJECT" { type = "string" }
variable "GOOGLE_REGION" { type = "string" }
variable "GOOGLE_ZONE" { type = "string" }
variable "CLUSTER_NAME" { type = "string" }
variable "GKE_HIGHMEM_MACHINE_TYPE" { type = "string" }
variable "GKE_HIGHMEM_AUTOSCALING_MIN_NODE_COUNT" { type = number }
variable "GKE_HIGHMEM_AUTOSCALING_MAX_NODE_COUNT" { type = number }

resource "google_container_cluster" "primary" {
  name = "${var.CLUSTER_NAME}"
  location = "${var.GOOGLE_ZONE}"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    http_load_balancing {
      disabled = true
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      # 3am PDT
      start_time = "10:00"
    }
  }

  # This setting is also known as "VPC native"
  ip_allocation_policy {
    use_ip_aliases = true
  }
}

resource "google_container_node_pool" "highmem" {
  cluster    = google_container_cluster.primary.name
  location   = var.GOOGLE_ZONE
  name       = "${var.CLUSTER_NAME}-highmem-node-pool"
  autoscaling {
    min_node_count = var.GKE_HIGHMEM_AUTOSCALING_MIN_NODE_COUNT
    max_node_count = var.GKE_HIGHMEM_AUTOSCALING_MAX_NODE_COUNT
  }

  node_config {
    preemptible  = true
    machine_type = var.GKE_HIGHMEM_MACHINE_TYPE

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

output "k8s_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "k8s_username" {
  value = google_container_cluster.primary.master_auth.0.username
}

output "k8s_password" {
  value = google_container_cluster.primary.master_auth.0.password
}

output "k8s_client_certificate" {
  value = google_container_cluster.primary.master_auth.0.client_certificate
}

output "k8s_client_key" {
  value = google_container_cluster.primary.master_auth.0.client_key
}

output "k8s_cluster_ca_certificate" {
  value = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
}

output "k8s_cluster_network" {
  value = google_container_cluster.primary.network
}
