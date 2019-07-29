variable "SHORT_HASH" { type = "string" }
variable "DOCKER_PREFIX" { type = "string" }
variable "POSTGRES_USERNAME" { type = "string" }
variable "POSTGRES_PASSWORD" { type = "string" }
variable "POSTGRES_HOST" { type = "string" }
variable "POSTGRES_DB_NAME" { type = "string" }

locals {
  docker_image = "${var.DOCKER_PREFIX}rambler:${var.SHORT_HASH}"
}

resource "null_resource" "docker" {
  triggers = {
    SHORT_HASH = var.SHORT_HASH
  }

  provisioner "local-exec" {
    working_dir = "./rambler"
    command = <<EOF
      docker build -t ${local.docker_image} .;
      docker push ${local.docker_image};
    EOF
  }
}

resource "kubernetes_job" "job" {
  metadata {
    name = "rambler"
  }
  spec {
    template {
      metadata {
        name = "rambler"
        labels = {
          app = "rambler"
        }
      }

      spec {
        restart_policy = "Never"
        container {
          name = "rambler"
          image = local.docker_image
          command = ["./apply-all.bash"]
          resources{
            requests {
              cpu = "100m"
              memory = "100Mi"
            }
            limits {
              cpu = "200m"
              memory = "200Mi"
            }
          }

          env {
            name = "SHORT_HASH"
            value = var.SHORT_HASH
          }

          env {
            name = "RAMBLER_PROTOCOL"
            value = "tcp"
          }

          env {
            name = "RAMBLER_DRIVER"
            value = "postgresql"
          }

          env {
            name = "RAMBLER_USER"
            value = var.POSTGRES_USERNAME
          }

          env {
            name = "RAMBLER_PASSWORD"
            value = var.POSTGRES_PASSWORD
          }

          env {
            name = "RAMBLER_HOST"
            value = var.POSTGRES_HOST
          }

          env {
            name = "RAMBLER_PORT"
            value = "5432"
          }

          env {
            name = "RAMBLER_DATABASE"
            value = var.POSTGRES_DB_NAME
          }

          env {
            name = "RAMBLER_TABLE"
            value = "migrations"
          }

          env {
            name = "RAMBLER_DIRECTORY"
            value = "migrations"
          }
        }
      }
    }
  }
}
