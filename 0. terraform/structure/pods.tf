resource "kubernetes_service" "api" {
  metadata {
    name = "api"
  }
  spec {
    selector {
      app = "${kubernetes_deployment.api.metadata.0.labels.app}"
    }

    port {
      port = 4000
      target_port = 4000
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "mongodb" {
  metadata {
    name = "mongodb"
    labels {
      app = "mongodb"
    }
  }
  spec {
    container {
      image = "mongo:3.5"
      name  = "mongodb"
    }
  }

  # Config do container
  spec {
    replicas = "1"
    selector {
      app = "grafana"
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels {
          app  = "grafana"
          name = "grafana"
        }
      }

      spec {
        container {
          image = "mirror.gcr.io/grafana/grafana:latest"
          name  = "grafana"

          liveness_probe {
            tcp_socket {
              port = 3000
            }

            failure_threshold     = 3
            initial_delay_seconds = 3
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 2
          }

          readiness_probe {
            tcp_socket {
              port = 3000
            }

            failure_threshold     = 1
            initial_delay_seconds = 10
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 2
          }

          resources {
            limits {
              cpu    = "200m"
              memory = "256M"
            }
          }

          port {
            name           = "http"
            container_port = 3000
            protocol       = "TCP"
          }

          env = [
            {
              name = "GF_SECURITY_ADMIN_PASSWORD"

              value_from {
                secret_key_ref {
                  key  = "grafana-root-password"
                  name = "${kubernetes_secret.grafana-secret.metadata.0.name}"
                }
              }
            },
            {
              name  = "GF_INSTALL_PLUGINS"
              value = "grafana-clock-panel,grafana-simple-json-datasource,grafana-piechart-panel"
            },
            {
              name  = "GF_PATH_PROVISIONING"
              value = "/etc/grafana/provisioning"
            },
          ]

          volume_mount {
            mount_path = "/var/lib/grafana"
            name       = "grafana-volume"
          }

          volume_mount {
            mount_path = "/etc/grafana/provisioning/datasources/"
            name       = "grafana-config-datasources"
          }

          volume_mount {
            mount_path = "/etc/grafana/provisioning/dashboards/"
            name       = "grafana-config-dashboards"
          }

          volume_mount {
            mount_path = "/etc/grafana/dashboards"
            name       = "grafana-dashboards"
          }
        }

        volume {
          name = "grafana-volume"
          persistent_volume_claim {
            claim_name = "${kubernetes_persistent_volume_claim.grafana-pv-claim.metadata.0.name}"
          }
        }

        volume {
          name = "grafana-config-datasources"
          secret {
            secret_name = "grafana-secret"
            items {
              key  = "datasources.yml"
              path = "datasources.yml"
            }
          }
        }

        volume {
          name = "grafana-config-dashboards"
          secret {
            secret_name = "grafana-secret"
            items {
              key  = "dashboards.yml"
              path = "dashboards.yml"
            }
          }
        }

        volume {
          name = "grafana-dashboards"
          config_map {
            name = "grafana-dashboards"
          }
        }

        # Must be set for persistent volume permissions
        # See http://docs.grafana.org/installation/docker/#user-id-changes
        security_context {
          fs_group = "472"
        }
      }
    }
  }
}
resource "kubernetes_deployment" "api" {
  metadata {
    name = "api-heroes"
    labels {
      app = "api-heroes"
    }
  }

  spec {
    replicas = 2
    container {
      image = "orixaliorus/api-herois:v1"
      name  = "api-heroes"

      port {
        container_port = 4000
      }
    }
  }
}