variable "PG_URL" { type = "string" }

locals {
  docker_image = "sosedoff/pgweb"
  name = "pgweb"
  port = 8081
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
            requests {
              cpu = "50m"
              memory = "250Mi"
            }
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
            name = "DATABASE_URL"
            value = var.PG_URL
          }
        }
      }
    }
  }
}
