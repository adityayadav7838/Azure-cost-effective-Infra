# Kubernetes Secret containing the PostgreSQL connection string (Requirement 7.7)
resource "kubernetes_secret" "db" {
  metadata {
    name      = "sample-app-db-secret"
    namespace = "default"
  }

  data = {
    DATABASE_URL = "postgresql://${urlencode(var.postgres_admin_username)}:${urlencode(var.postgres_admin_password)}@${var.postgres_fqdn}:5432/${var.postgres_database_name}?sslmode=require"
  }
}

# Docker Hub Registry Secret for Private Image Pulling
resource "kubernetes_secret" "dockerhub" {
  metadata {
    name      = "dockerhub-secret"
    namespace = "default"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://index.docker.io/v1/" = {
          username = var.docker_username
          password = var.docker_password
          auth     = base64encode("${var.docker_username}:${var.docker_password}")
        }
      }
    })
  }
}

# Kubernetes Deployment — 1 replica, reads DATABASE_URL from Secret (Requirements 7.1, 7.7)
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "sample-app"
    namespace = "default"
    labels = {
      app = "sample-app"
    }
  }

  spec {
    replicas = var.replica_count

    selector {
      match_labels = {
        app = "sample-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "sample-app"
        }
      }

      spec {
        # Attached Docker Hub pull secret
        image_pull_secrets {
          name = kubernetes_secret.dockerhub.metadata[0].name
        }

        container {
          name  = "sample-app"
          image = var.app_image

          port {
            container_port = 8000 # App listens on port 8000
          }

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "DATABASE_URL"
              }
            }
          }
        }
      }
    }
  }
}

# ClusterIP Service — exposes the app inside the cluster (Requirement 7.6)
resource "kubernetes_service" "app" {
  metadata {
    name      = "sample-app"
    namespace = "default"
  }

  spec {
    selector = {
      app = "sample-app"
    }

    type = "ClusterIP"

    port {
      port        = 80
      target_port = 8000 # Route service port 80 -> container port 8000
    }
  }
}

# Traefik Ingress — routes the DNS hostname to the ClusterIP service (Requirements 7.6, 6.4)
resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "sample-app"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.application_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}