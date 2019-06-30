variable "ALERTS_SLACK_WEBHOOK_URL" { type = "string" }
variable "ALERTS_SLACK_CHANNEL" { type = "string" }

variable "PG_EXPORTER_HOST" { type = "string" }
variable "API_EXPORTER_HOST" { type = "string" }
variable "PROMETHEUS_ASSETS_EXPORTER_HOST" { type = "string" }
variable "WEB_URL" { type = "string" }
variable "NGINX_INGRESS_EXPORTER_HOST" { type = "string" }

data "template_file" "values" {
  template = "${file("${path.module}/values.yml")}"
  vars = {
    ALERTS_SLACK_WEBHOOK_URL = var.ALERTS_SLACK_WEBHOOK_URL
    ALERTS_SLACK_CHANNEL = var.ALERTS_SLACK_CHANNEL

    PG_EXPORTER_HOST = var.PG_EXPORTER_HOST
    API_EXPORTER_HOST = var.API_EXPORTER_HOST
    PROMETHEUS_ASSETS_EXPORTER_HOST = var.PROMETHEUS_ASSETS_EXPORTER_HOST
    WEB_URL = var.WEB_URL
    NGINX_INGRESS_EXPORTER_HOST = var.NGINX_INGRESS_EXPORTER_HOST
  }
}

resource "helm_release" "main" {
  name = "prometheus"
  chart = "stable/prometheus"
  values = [
    data.template_file.values.rendered
  ]
}
