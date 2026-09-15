# Cluster EKS declarado com recursos nativos do provider AWS, em vez do
# módulo terraform-aws-modules/eks. Motivo: aquele módulo declara, de forma
# incondicional (em qualquer versão testada, v19 a v20), um
# data "aws_iam_session_context" que chama iam:GetRole pra resolver a
# identidade de quem está aplicando — e o AWS Academy nega explicitamente
# iam:GetRole pra qualquer role que não seja a LabRole (política Pvoclabs2),
# quebrando o plan/apply antes mesmo de criar qualquer recurso.
#
# Não precisamos dessa resolução: a própria API do EKS já concede acesso de
# administrador a quem cria o cluster (usando o contexto da chamada de API
# em si, não uma consulta de IAM em separado) — é exatamente esse mecanismo
# nativo que usamos aqui, sem nenhum data source de IAM extra.

resource "aws_eks_cluster" "this" {
  name     = "${var.project_name}-eks"
  role_arn = var.lab_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = module.vpc.private_subnets
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  # Sem access_config customizado: mantém o comportamento padrão da AWS de
  # conceder admin a quem cria o cluster, sem exigir nenhuma chamada de IAM
  # adicional da nossa parte.
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = var.lab_role_arn
  subnet_ids      = module.vpc.private_subnets

  instance_types = var.node_instance_types

  scaling_config {
    min_size     = var.node_min_size
    max_size     = var.node_max_size
    desired_size = var.node_desired_size
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  # Evita loop de recriação se o desired_size mudar por causa de scaling
  # automático (não usamos autoscaler aqui, mas é uma prática segura).
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Sem EBS CSI driver: o MySQL virou RDS, não sobrou nenhum PV dentro do
# cluster, então não precisamos desse addon (e ele pediria IRSA/IAM extra).
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.default]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.default]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # vpc-cni roda antes dos nodes existirem (é ele que dá IP às pods), mas
  # deixamos depender do cluster só, sem depender do node group.
  depends_on = [aws_eks_cluster.this]
}
