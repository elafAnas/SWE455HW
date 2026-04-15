terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# -------------------------
# Variables
# -------------------------
variable "project_id" {}
variable "region" {
  default = "us-central1"
}

variable "service1_image" {}
variable "service2_image" {}

# -------------------------
# Enable APIs
# -------------------------
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}

resource "google_project_service" "pubsub_api" {
  service = "pubsub.googleapis.com"
}

resource "google_project_service" "apigateway_api" {
  service = "apigateway.googleapis.com"
}

resource "google_project_service" "servicemanagement_api" {
  service = "servicemanagement.googleapis.com"
}

resource "google_project_service" "servicecontrol_api" {
  service = "servicecontrol.googleapis.com"
}

# -------------------------
# Pub/Sub Topic
# -------------------------
resource "google_pubsub_topic" "pi_topic" {
  name = "pi-topic"
}

# -------------------------
# Cloud Run Service 1
# -------------------------
resource "google_cloud_run_v2_service" "service1" {
  name     = "service1"
  location = var.region

  template {
    containers {
      image = var.service1_image

      ports {
        container_port = 8080
      }

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "TOPIC_ID"
        value = google_pubsub_topic.pi_topic.name
      }
    }
  }
}

# Public access to service1
resource "google_cloud_run_v2_service_iam_member" "service1_public" {
  name     = google_cloud_run_v2_service.service1.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# -------------------------
# Cloud Run Service 2
# -------------------------
resource "google_cloud_run_v2_service" "service2" {
  name     = "service2"
  location = var.region

  template {
    containers {
      image = var.service2_image

      ports {
        container_port = 8080
      }
    }
  }
}

# Public access to service2
resource "google_cloud_run_v2_service_iam_member" "service2_public" {
  name     = google_cloud_run_v2_service.service2.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# -------------------------
# Pub/Sub Subscription → Service 2
# -------------------------
resource "google_pubsub_subscription" "pi_sub" {
  name  = "pi-sub"
  topic = google_pubsub_topic.pi_topic.name

  push_config {
    push_endpoint = google_cloud_run_v2_service.service2.uri
  }
}

# -------------------------
# API Gateway
# -------------------------
resource "google_api_gateway_api" "api" {
  provider = google-beta
  api_id   = "pi-api"
}

resource "google_api_gateway_api_config" "api_config" {
  provider      = google-beta
  api           = google_api_gateway_api.api.api_id
  api_config_id = "pi-config"

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = filebase64("openapi.yaml")
    }
  }
}

resource "google_api_gateway_gateway" "gateway" {
  provider   = google-beta
  api_config = google_api_gateway_api_config.api_config.id
  gateway_id = "pi-gateway"
  region     = var.region
}

# -------------------------
# Outputs
# -------------------------
output "service1_url" {
  value = google_cloud_run_v2_service.service1.uri
}

output "service2_url" {
  value = google_cloud_run_v2_service.service2.uri
}

output "gateway_url" {
  value = google_api_gateway_gateway.gateway.default_hostname
}