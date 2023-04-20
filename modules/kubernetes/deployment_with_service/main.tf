terraform {
  required_version = "~> 1.3"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }
  }

  backend "azurerm" {}
}

provider "kubernetes" {
  config_path = var.config_path
}

resource "kubernetes_deployment_v1" "deployment" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app = var.name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = {
          "io.kompose.service" = var.name
          app                  = var.name
        }
      }

      spec {
        container {
          image             = var.docker_image
          image_pull_policy = "Always"
          name              = var.name

          resources {
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
          }

          port {
            container_port = var.container_port
          }

          dynamic "readiness_probe" {
            for_each = var.readiness_probe ? [1] : []

            content {
              http_get {
                path   = readiness_probe.value.path
                port   = readiness_probe.value.port
                scheme = "HTTP"
              }

              initial_delay_seconds = 10
              period_seconds        = 10
              failure_threshold     = 3
              timeout_seconds       = 5
            }
          }

          dynamic "liveness_probe" {
            for_each = var.liveness_probe ? [1] : []

            content {
              http_get {
                path   = liveness_probe.value.path
                port   = liveness_probe.value.port
                scheme = "HTTP"
              }

              initial_delay_seconds = 10
              period_seconds        = 10
              failure_threshold     = 3
              timeout_seconds       = 5
            }
          }
        }

        restart_policy = "Always"
      }
    }
  }
}

resource "kubernetes_service_v1" "service" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.deployment.metadata[0].name
    }

    port {
      port        = var.container_port
      target_port = var.target_port
    }

    type = "ClusterIP"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
    ]
  }
}

resource "kubernetes_manifest" "http-scaler" {
  count = var.scaler != null && var.scaler.type == "http" ? 1 : 0

  manifest = {
    kind       = "HTTPScaledObject"
    apiVersion = "http.keda.sh/v1alpha1"
    metadata = {
      name = var.name
    }
    spec = {
      host = var.scaler.host
      scaleTargetRef = {
        deployment = var.name
        service    = var.name
        port       = var.container_port
      }
      replicas = {
        min = var.scaler.replicas.min
        max = var.scaler.replicas.max
      }
    }
  }
}