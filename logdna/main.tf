variable "LOGDNA_INGESTION_KEY" { type = "string" }

resource "helm_release" "main" {
  name = "logdna-agent"
  repository = "stable"
  chart = "logdna-agent"

  set {
    name = "logdna.key"
    value = var.LOGDNA_INGESTION_KEY
  }

  set {
    name = "logdna.update"
    value = 1
  }
}
