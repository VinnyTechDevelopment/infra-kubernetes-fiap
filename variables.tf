variable "aws_region" {
  description = "Região AWS onde a infraestrutura será criada"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto, usado como prefixo em todos os recursos"
  type        = string
  default     = "techchallenge"
}

variable "environment" {
  description = "Ambiente (ex: production, staging)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "cluster_version" {
  description = "Versão do Kubernetes no EKS"
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "Tipos de instância EC2 para o node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 5
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "lab_role_arn" {
  description = "ARN da LabRole do AWS Academy (ex: arn:aws:iam::123456789012:role/LabRole). Usada no lugar de criar roles IAM novas, que o Academy não permite."
  type        = string
}
