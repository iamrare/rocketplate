variable "SHORT_HASH" { type = "string" }
variable "DOCKER_PREFIX" { type = "string" }
variable "PG_WRITE_URL" { type = "string" }
variable "PG_READ_URL" { type = "string" }

locals {
  docker_image = "${var.DOCKER_PREFIX}api:${var.SHORT_HASH}"
}

resource "kubernetes_service" "api" {
  metadata {
    name = "api"
    labels = {
      app = "api"
    }
  }

  spec {
    port {
      port = 3000
      target_port = 3000
    }

    selector =  {
      app = "api"
    }
  }
}

resource "null_resource" "docker" {
  triggers = {
    SHORT_HASH = var.SHORT_HASH
  }

  provisioner "local-exec" {
    working_dir = "./api"
    command = <<EOF
      docker build -q -t ${local.docker_image} .;
      docker push ${local.docker_image};
    EOF
  }
}

resource "kubernetes_deployment" "api" {
  depends_on = [null_resource.docker]

  metadata {
    name = "api"
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
        app = "api"
      }
    }

    template {
      metadata {
        labels = {
          app = "api"
        }
      }

      spec {
        container {
          name = "api"
          image = "${local.docker_image}"
          image_pull_policy = "Always"
          resources {
            limits {
              cpu = "500m"
              memory = "500Mi"
            }
          }

          port {
            container_port = 3000
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            timeout_seconds = 30
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 30
            timeout_seconds = 30
          }

          env {
            name = "NODE_ENV"
            value = "production"
          }

          env {
            name = "SHORT_HASH"
            value = var.SHORT_HASH
          }

          env {
            name = "PORT"
            value = 3000
          }

          env {
            name = "PG_WRITE_URL"
            value = var.PG_WRITE_URL
          }

          env {
            name = "PG_READ_URL"
            value = var.PG_READ_URL
          }
        }
      }
    }
  }
}
