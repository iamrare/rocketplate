variable "GOOGLE_REGION" { type = "string" }
variable "GOOGLE_ZONE" { type = "string" }
variable "POSTGRES_MASTER_INSTANCE_NAME" { type = "string" }
variable "POSTGRES_MASTER_IP_ADDRESS_NAME" { type = "string" }
variable "POSTGRES_DB_NAME" { type = "string" }
variable "POSTGRES_USERNAME" { type = "string" }
variable "POSTGRES_PASSWORD" { type = "string" }
variable "K8S_CLUSTER_NETWORK" { type = "string" }

resource "google_compute_global_address" "private_ip_address" {
  provider = "google-beta"

  name = var.POSTGRES_MASTER_IP_ADDRESS_NAME
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 16
  network = var.K8S_CLUSTER_NETWORK
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = "google-beta"

  network = var.K8S_CLUSTER_NETWORK
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "master" {
  provider = "google-beta"

  name = var.POSTGRES_MASTER_INSTANCE_NAME
  database_version = "POSTGRES_9_6"
  region = var.GOOGLE_REGION

  depends_on = [
    "google_service_networking_connection.private_vpc_connection"
  ]

  settings {
    location_preference {
      zone = var.GOOGLE_ZONE
    }

    maintenance_window {
      # Saturday
      day = 6
      # 3am PDT
      hour = 10
    }

    tier = "db-custom-1-3840"

    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled = false
      private_network = var.K8S_CLUSTER_NETWORK
    }
    backup_configuration {
      enabled = true
      # 3am PDT
      start_time = "10:00"
    }
  }
}

resource "google_sql_user" "user" {
  name = var.POSTGRES_USERNAME
  instance = google_sql_database_instance.master.name
  password = var.POSTGRES_PASSWORD
}

resource "google_sql_database" "db" {
  name = var.POSTGRES_DB_NAME
  instance = google_sql_database_instance.master.name
}

output "instance_ip_address" {
  value = google_compute_global_address.private_ip_address.address
}
