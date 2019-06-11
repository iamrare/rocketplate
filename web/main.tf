variable "SHORT_HASH" { type = "string" }
variable "DOCKER_PREFIX" { type = "string" }

locals {
  docker_image = "${var.DOCKER_PREFIX}web:${var.SHORT_HASH}"
}

resource "kubernetes_service" "web" {
  metadata {
    name = "web"
    labels = {
      app = "web"
    }
  }

  spec {
    port {
      port = 3000
      target_port = 3000
    }

    selector =  {
      app = "web"
    }
  }
}

resource "null_resource" "docker" {
  triggers = {
    SHORT_HASH = var.SHORT_HASH
  }

  provisioner "local-exec" {
    working_dir = "./web"
    command = <<EOF
      docker build -t ${local.docker_image} .;
      docker push ${local.docker_image};
    EOF
  }
}

resource "kubernetes_deployment" "web" {
  depends_on = [null_resource.docker]

  metadata {
    name = "web"
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
        app = "web"
      }
    }

    template {
      metadata {
        labels = {
          app = "web"
        }
      }

      spec {
        container {
          name = "web"
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
            initial_delay_seconds = 60
            timeout_seconds = 30
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 60
            timeout_seconds = 10
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
        }
      }
    }
  }
}
