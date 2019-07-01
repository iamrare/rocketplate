resource "kubernetes_config_map" "prometheus_datasource" {
  metadata {
    name = "prometheus-datasource"
    labels = {
      grafana_datasource = 1
    }
  }

  data = {
    "datasources.yml" = <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: direct
    url: http://prometheus:9090
    disableDeletion: true
    editable: false
EOF
  }
}

resource "kubernetes_config_map" "prometheus_dashboard" {
  metadata {
    name = "prometheus-dashboard"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "prometheus-dashboard.json" = "${file("${path.module}/production-provisioning/dashboards/prometheus.json")}"
  }
}

resource "helm_release" "main" {
  name = "grafana"
  chart = "stable/grafana"

  values = [
    <<EOF
sidecar:
  dashboards:
    enabled: true

  datasources:
    enabled: true

env:
  GF_AUTH_ANONYMOUS_ENABLED: true
  GF_AUTH_ANONYMOUS_ORG_ROLE: Admin
EOF
  ]
}
