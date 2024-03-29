terraform {
  backend "gcs" {
  }
}

# ---

variable "GOOGLE_PROJECT" { type = "string" }
variable "GOOGLE_REGION" { type = "string" }
variable "GOOGLE_ZONE" { type = "string" }
variable "CLUSTER_NAME" { type = "string" }
variable "GKE_HIGHMEM_MACHINE_TYPE" { type = "string" }
variable "GKE_HIGHMEM_AUTOSCALING_MIN_NODE_COUNT" { type = number }
variable "GKE_HIGHMEM_AUTOSCALING_MAX_NODE_COUNT" { type = number }

variable "STATIC_IP_NAME" { type = "string" }
variable "DOMAIN_NAME" { type = "string" }
variable "MANAGED_ZONE_NAME" { type = "string" }
variable "LETS_ENCRYPT_EMAIL" { type = "string" }
variable "LETS_ENCRYPT_URL" { type = "string" }
variable "DOCKER_PREFIX" { type = "string" }
variable "POSTGRES_MASTER_INSTANCE_NAME" { type = "string" }
variable "POSTGRES_MASTER_IP_ADDRESS_NAME" { type = "string" }
variable "POSTGRES_DB_NAME" { type = "string" }
variable "POSTGRES_USERNAME" { type = "string" }
variable "POSTGRES_PASSWORD" { type = "string" }
variable "ALERTS_SLACK_WEBHOOK_URL" { type = "string" }
variable "ALERTS_SLACK_CHANNEL" { type = "string" }
variable "LOGDNA_INGESTION_KEY" { type = "string" }

# ---

provider "archive" {
  version = "~> 1.2"
}

provider "external" {
  version = "~> 1.1"
}

data "external" "SHORT_HASH" {
  program = ["./git-short-hash.bash"]
}

provider "null" {
  version = "~> 2.1"
}

provider "google" {
  version = "~> 2.7"
  project = "${var.GOOGLE_PROJECT}"
  region = "${var.GOOGLE_REGION}"
  zone = "${var.GOOGLE_ZONE}"
}

provider "google-beta" {
  version = "~> 2.8"
  project = "${var.GOOGLE_PROJECT}"
  region = "${var.GOOGLE_REGION}"
  zone = "${var.GOOGLE_ZONE}"
}

module "cloud-build-alert" {
  source = "./cloud-build-alert"

  ALERTS_SLACK_WEBHOOK_URL = var.ALERTS_SLACK_WEBHOOK_URL
}

module "gke" {
  source = "./gke"

  GOOGLE_PROJECT = var.GOOGLE_PROJECT
  GOOGLE_REGION = var.GOOGLE_REGION
  GOOGLE_ZONE = var.GOOGLE_ZONE
  CLUSTER_NAME = var.CLUSTER_NAME
  GKE_HIGHMEM_MACHINE_TYPE = var.GKE_HIGHMEM_MACHINE_TYPE
  GKE_HIGHMEM_AUTOSCALING_MIN_NODE_COUNT = var.GKE_HIGHMEM_AUTOSCALING_MIN_NODE_COUNT
  GKE_HIGHMEM_AUTOSCALING_MAX_NODE_COUNT = var.GKE_HIGHMEM_AUTOSCALING_MAX_NODE_COUNT
}

# Authenticate the k8s cluster the first time it's created.
#
# You can't define module.depends_on, so there might be a race condition for
# the first deploy, as the modules try to deploy themselves without k8s
# credentials
resource "null_resource" "gke_credentials" {
  triggers = {
    GKE = module.gke.k8s_endpoint
  }

  provisioner "local-exec" {
    command = <<EOF
      gcloud container clusters get-credentials ${var.CLUSTER_NAME} \
        --zone=${var.GOOGLE_ZONE}
    EOF
  }
}

provider "kubernetes" {
  version = "~> 1.8"

  host = "https://${module.gke.k8s_endpoint}"
  username = "${module.gke.k8s_username}"
  password = "${module.gke.k8s_password}"
  client_certificate = "${base64decode(module.gke.k8s_client_certificate)}"
  client_key = "${base64decode(module.gke.k8s_client_key)}"
  cluster_ca_certificate = "${base64decode(module.gke.k8s_cluster_ca_certificate)}"
}

resource "kubernetes_service_account" "tiller" {
  depends_on = [null_resource.gke_credentials]

  metadata {
    name = "terraform-tiller"
    namespace = "kube-system"
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "tiller" {
  depends_on = [null_resource.gke_credentials]

  metadata {
    name = "terraform-tiller"
  }

  role_ref {
    kind = "ClusterRole"
    name = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind = "ServiceAccount"
    name = "terraform-tiller"

    api_group = ""
    namespace = "kube-system"
  }
}

provider "helm" {
  version = "~> 0.9"
  install_tiller = true

  kubernetes {
    host = "https://${module.gke.k8s_endpoint}"
    username = "${module.gke.k8s_username}"
    password = "${module.gke.k8s_password}"
    client_certificate = "${base64decode(module.gke.k8s_client_certificate)}"
    client_key = "${base64decode(module.gke.k8s_client_key)}"
    cluster_ca_certificate = "${base64decode(module.gke.k8s_cluster_ca_certificate)}"
  }

  service_account = "${kubernetes_service_account.tiller.metadata.0.name}"
  namespace       = "${kubernetes_service_account.tiller.metadata.0.namespace}"
  tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.11.0"
}

module "ingress" {
  source = "./ingress"

  STATIC_IP_NAME = var.STATIC_IP_NAME
  DOMAIN_NAME = var.DOMAIN_NAME
  MANAGED_ZONE_NAME = var.MANAGED_ZONE_NAME
  LETS_ENCRYPT_EMAIL = var.LETS_ENCRYPT_EMAIL
  LETS_ENCRYPT_URL = var.LETS_ENCRYPT_URL
}

module "logdna" {
  source = "./logdna"

  LOGDNA_INGESTION_KEY = var.LOGDNA_INGESTION_KEY
}

module "web" {
  source = "./web"

  SHORT_HASH = data.external.SHORT_HASH.result.SHORT_HASH
  DOCKER_PREFIX = var.DOCKER_PREFIX
}

module "postgres" {
  source = "./postgres"

  GOOGLE_REGION = var.GOOGLE_REGION
  GOOGLE_ZONE = var.GOOGLE_ZONE
  POSTGRES_MASTER_INSTANCE_NAME = var.POSTGRES_MASTER_INSTANCE_NAME
  POSTGRES_MASTER_IP_ADDRESS_NAME = var.POSTGRES_MASTER_IP_ADDRESS_NAME
  POSTGRES_DB_NAME = var.POSTGRES_DB_NAME
  POSTGRES_USERNAME = var.POSTGRES_USERNAME
  POSTGRES_PASSWORD = var.POSTGRES_PASSWORD
  K8S_CLUSTER_NETWORK = module.gke.k8s_cluster_network
}

module "rambler" {
  source = "./rambler"

  SHORT_HASH = data.external.SHORT_HASH.result.SHORT_HASH
  DOCKER_PREFIX = var.DOCKER_PREFIX
  POSTGRES_USERNAME = var.POSTGRES_USERNAME
  POSTGRES_PASSWORD = var.POSTGRES_PASSWORD
  POSTGRES_HOST = module.postgres.instance_ip_address
  POSTGRES_DB_NAME = var.POSTGRES_DB_NAME
}

module "api" {
  source = "./api"

  SHORT_HASH = data.external.SHORT_HASH.result.SHORT_HASH
  DOCKER_PREFIX = var.DOCKER_PREFIX
  PG_WRITE_URL = "postgres://${var.POSTGRES_USERNAME}:${var.POSTGRES_PASSWORD}@${module.postgres.instance_ip_address}:5432/${var.POSTGRES_DB_NAME}"
  PG_READ_URL = "postgres://${var.POSTGRES_USERNAME}:${var.POSTGRES_PASSWORD}@${module.postgres.instance_ip_address}:5432/${var.POSTGRES_DB_NAME}"
}

module "pgweb" {
  source = "./pgweb"

  PG_URL = "postgres://${var.POSTGRES_USERNAME}:${var.POSTGRES_PASSWORD}@${module.postgres.instance_ip_address}:5432/${var.POSTGRES_DB_NAME}"
}

module "postgres-exporter" {
  source = "./postgres-exporter"

  PG_URL = "postgres://${var.POSTGRES_USERNAME}:${var.POSTGRES_PASSWORD}@${module.postgres.instance_ip_address}:5432/${var.POSTGRES_DB_NAME}"
}

module "prometheus-assets" {
  source = "./prometheus-assets"
}

module "prometheus" {
  source = "./prometheus"

  ALERTS_SLACK_WEBHOOK_URL = var.ALERTS_SLACK_WEBHOOK_URL
  ALERTS_SLACK_CHANNEL = var.ALERTS_SLACK_CHANNEL

  PG_EXPORTER_HOST = "postgres-exporter:9187"
  API_EXPORTER_HOST = "api:3000"
  PROMETHEUS_ASSETS_EXPORTER_HOST = "prometheus-assets:3000"
  WEB_URL = "https://${var.DOMAIN_NAME}"
  NGINX_INGRESS_EXPORTER_HOST = "nginx-ingress-controller-metrics:9913"
}

module "grafana" {
  source = "./grafana"
}
