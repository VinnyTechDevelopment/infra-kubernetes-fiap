# Integração do New Relic com o cluster (consumo de CPU/memória dos pods,
# healthchecks, eventos e logs do Kubernetes) via nri-bundle. Ligada por
# padrão: a License Key vem do secret de organização NEWRELIC_LICENSE_KEY
# (ver .github/workflows/terraform.yml). Só desligue (newrelic_enabled =
# false) para rodar o cluster localmente sem conta New Relic.

variable "newrelic_enabled" {
  description = "Liga a integração de infraestrutura do New Relic no cluster (helm_release nri-bundle)."
  type        = bool
  default     = true
}

variable "newrelic_license_key" {
  description = "License key do New Relic (Infrastructure). Obrigatória quando newrelic_enabled = true."
  type        = string
  sensitive   = true
  default     = ""
}

# Falha no plan (em vez de subir o nri-bundle com chave vazia e o cluster
# ficar "ligado" no código mas sem reportar nada no New Relic).
check "newrelic_license_key_presente" {
  assert {
    condition     = !var.newrelic_enabled || length(var.newrelic_license_key) > 0
    error_message = "newrelic_enabled = true exige newrelic_license_key (secret NEWRELIC_LICENSE_KEY)."
  }
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

  depends_on = [aws_eks_node_group.default, aws_eks_addon.vpc_cni]
}
