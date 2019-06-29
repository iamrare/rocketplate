variable "POSTGRES_HOST" { type = "string" }
variable "POSTGRES_DB_NAME" { type = "string" }

locals {
  docker_image = "dockage/phppgadmin"
  name = "phppgadmin"
  port = 80
}

resource "kubernetes_service" "main" {
  metadata {
    name = local.name
    labels = {
      app = local.name
    }
  }

  spec {
    port {
      port = local.port
      target_port = local.port
    }

    selector =  {
      app = local.name
    }
  }
}

resource "kubernetes_deployment" "main" {
  metadata {
    name = local.name
  }

  spec {
    replicas = 1
    revision_history_limit = 2
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = 1
        max_surge = 3
      }
    }

    selector {
      match_labels = {
        app = local.name
      }
    }

    template {
      metadata {
        labels = {
          app = local.name
        }
      }

      spec {
        container {
          name = local.name
          image = "${local.docker_image}"
          image_pull_policy = "Always"
          resources {
            limits {
              cpu = "100m"
              memory = "500Mi"
            }
          }

          port {
            container_port = local.port
          }

          liveness_probe {
            http_get {
              path = "/"
              port = local.port
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            timeout_seconds = 5
            period_seconds = 5
            failure_threshold = 60
          }

          readiness_probe {
            http_get {
              path = "/"
              port = local.port
            }
            initial_delay_seconds = 30
            timeout_seconds = 5
            period_seconds = 30
          }

          env {
            name = "PHP_PG_ADMIN_SERVER_DESC"
            value = var.POSTGRES_DB_NAME
          }

          env {
            name = "PHP_PG_ADMIN_SERVER_HOST"
            value = var.POSTGRES_HOST
          }

          env {
            name = "PHP_PG_ADMIN_SERVER_DEFAULT_DB"
            value = var.POSTGRES_DB_NAME
          }
        }
      }
    }
  }
}
