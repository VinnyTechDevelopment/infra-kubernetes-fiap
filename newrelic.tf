# Integração opcional do New Relic com o cluster (consumo de CPU/memória dos
# pods, healthchecks, eventos do Kubernetes). Desligada por padrão
# (newrelic_enabled = false) porque o usuário ainda não tem conta/License Key
# do New Relic — quando tiver, é só setar newrelic_enabled = true e preencher
# newrelic_license_key via tfvars/secret.

variable "newrelic_enabled" {
  description = "Liga a integração de infraestrutura do New Relic no cluster (helm_release nri-bundle). Fica false até existir uma conta/License Key."
  type        = bool
  default     = false
}

variable "newrelic_license_key" {
  description = "License key do New Relic (Infrastructure). Obrigatória só quando newrelic_enabled = true."
  type        = string
  sensitive   = true
  default     = ""
}

variable "newrelic_cluster_name" {
  description = "Nome do cluster como deve aparecer no New Relic (tag/atributo global.cluster do nri-bundle)."
  type        = string
  default     = "techchallenge-eks"
}

resource "helm_release" "newrelic_bundle" {
  count = var.newrelic_enabled ? 1 : 0

  name             = "newrelic-bundle"
  repository       = "https://helm-charts.newrelic.com"
  chart            = "nri-bundle"
  namespace        = "newrelic"
  create_namespace = true

  set {
    name  = "global.licenseKey"
    value = var.newrelic_license_key
  }

  set {
    name  = "global.cluster"
    value = var.newrelic_cluster_name
  }

  set {
    name  = "ksm.enabled"
    value = "true"
  }

  set {
    name  = "kubeEvents.enabled"
    value = "true"
  }

  set {
    name  = "logging.enabled"
    value = "true"
  }

  set {
    name  = "infrastructure.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.enabled"
    value = "false"
  }

  depends_on = [module.eks]
}
