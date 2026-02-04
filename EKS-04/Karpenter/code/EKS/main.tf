locals {
  env = var.env
}

module "eks" {
  source = "../modules"

  aws_region                = var.aws_region
  env                       = var.env
  cluster_name              = "${local.env}-${var.cluster_name}"
  vpc_cidr_block            = var.vpc_cidr_block
  vpc_name                  = "${local.env}-${var.vpc_name}"
  igw_name                  = "${local.env}-${var.igw_name}"
  public_subnet_count       = var.public_subnet_count
  public_subnet_cidr_block  = var.public_subnet_cidr_block
  availability_zones        = var.availability_zones
  public_subnet_name        = "${local.env}-${var.public_subnet_name}"
  private_subnet_count      = var.private_subnet_count
  private_subnet_cidr_block = var.private_subnet_cidr_block
  #   pri-availability-zone = var.pri-availability-zone
  private_subnet_name      = "${local.env}-${var.private_subnet_name}"
  public_route_table_name  = "${local.env}-${var.public_route_table_name}"
  private_route_table_name = "${local.env}-${var.private_route_table_name}"
  eip_name                 = "${local.env}-${var.eip_name}"
  nat_gateway_name         = "${local.env}-${var.nat_gateway_name}"
  eks-sg                   = var.eks-sg

  create_eks_cluster_role   = true
  create_eks_nodegroup_role = true
  instance_types            = var.instance_types
  desired_capacity = var.desired_capacity
  min_capacity     = var.min_capacity
  max_capacity     = var.max_capacity
  create_eks_cluster      = var.create_eks_cluster
  kubernetes_version      = var.kubernetes_version
  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access

  addons = var.addons
}