variable "STATIC_IP_NAME" { type = "string" }
variable "DOMAIN_NAME" { type = "string" }
variable "MANAGED_ZONE_NAME" { type = "string" }
variable "LETS_ENCRYPT_EMAIL" { type = "string" }
variable "LETS_ENCRYPT_URL" { type = "string" }

resource "google_compute_address" "ip" {
  name = "${var.STATIC_IP_NAME}"
}

resource "google_dns_managed_zone" "dns" {
  name     = "${var.MANAGED_ZONE_NAME}"
  dns_name = "${var.DOMAIN_NAME}."
}

resource "google_dns_record_set" "web" {
  name = "${google_dns_managed_zone.dns.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = "${google_dns_managed_zone.dns.name}"

  rrdatas = ["${google_compute_address.ip.address}"]
}

resource "helm_release" "nginx_ingress" {
  name = "nginx-ingress"
  chart = "stable/nginx-ingress"

  set {
    name = "external-dns.alpha.kubernetes.io/hostname"
    value = "${var.DOMAIN_NAME}"
  }

  set {
    name = "controller.metrics.enabled"
    value = true
  }

  set {
    name = "controller.service.loadBalancerIP"
    value = "${google_compute_address.ip.address}"
  }

  set {
    name = "defaultBackend.enabled"
    value = false
  }

  set {
    name = "controller.defaultBackendService"
    value = "default/web"
  }

  set {
    name = "image.tag"
    value = "0.1.7"
  }

  set {
    name = "image.pullPolicy"
    value = "Always"
  }
}

resource "helm_release" "kube_lego" {
  name = "kube-lego"
  chart = "stable/kube-lego"

  set {
    name = "config.LEGO_EMAIL"
    value = "${var.LETS_ENCRYPT_EMAIL}"
  }

  set {
    name = "config.LEGO_URL"
    value = "${var.LETS_ENCRYPT_URL}"
  }

  set {
    name = "config.LEGO_SUPPORTED_INGRESS_CLASS"
    value = "nginx"
  }

  set {
    name = "config.LEGO_SUPPORTED_INGRESS_PROVIDER"
    value = "nginx"
  }

  set {
    name = "rbac.create"
    value = true
  }
}

resource "kubernetes_ingress" "ingress" {
  metadata {
    name = "ingress"
    annotations = {
      "kubernetes.io/tls-acme" = "true"
      "kubernetes.io/ingress.class" = "nginx"

      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    tls {
      secret_name = "tls-secret"
      hosts = ["${var.DOMAIN_NAME}"]
    }

    rule {
      host = "${var.DOMAIN_NAME}"
      http {
        path {
          path = "/"
          backend {
            service_name = "web"
            service_port = 3000
          }
        }

        path {
          path = "/api"
          backend {
            service_name = "api"
            service_port = 3000
          }
        }

        path {
          path = "/api/*"
          backend {
            service_name = "api"
            service_port = 3000
          }
        }
      }
    }
  }
}
