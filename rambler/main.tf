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

resource "null_resource" "k8s" {
  triggers = {
    docker_image = "${null_resource.docker.id}"
  }

  provisioner "local-exec" {
    working_dir = "./rambler"
    command = <<EOF
      k8s_config=$(cat << K8S
apiVersion: batch/v1
kind: Job
metadata:
  name: rambler
spec:
  template:
    metadata:
      name: rambler
      labels:
        app: rambler
    spec:
      restartPolicy: Never
      containers:
      - name: rambler
        image: ${local.docker_image}
        command: ["./apply-all.bash"]
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
          limits:
            cpu: 200m
            memory: 200Mi
        env:
          - name: RAMBLER_PROTOCOL
            value: tcp
          - name: RAMBLER_DRIVER
            value: postgresql
          - name: RAMBLER_USER
            value: ${var.POSTGRES_USERNAME}
          - name: RAMBLER_PASSWORD
            value: ${var.POSTGRES_PASSWORD}
          - name: RAMBLER_HOST
            value: "${var.POSTGRES_HOST}"
          - name: RAMBLER_PORT
            value: "5432"
          - name: RAMBLER_DATABASE
            value: ${var.POSTGRES_DB_NAME}
          - name: RAMBLER_TABLE
            value: migrations
          - name: RAMBLER_DIRECTORY
            value: migrations
K8S)
      kubectl delete jobs/rambler
      echo "$k8s_config" | kubectl apply -f -
    EOF
  }
}
