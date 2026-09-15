data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = [cidrsubnet(var.vpc_cidr, 4, 0), cidrsubnet(var.vpc_cidr, 4, 1)]
  public_subnets  = [cidrsubnet(var.vpc_cidr, 4, 8), cidrsubnet(var.vpc_cidr, 4, 9)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Tags exigidas pelo EKS/ALB para descobrir as subnets automaticamente
  public_subnet_tags = {
    "kubernetes.io/role/elb"                       = 1
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"              = 1
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
