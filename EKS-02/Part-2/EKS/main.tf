locals {
  env = var.env
  org = "YT"
}


module "eks" {
  source = "../modules"

  env                      = var.env
  cluster_name             = "${local.env}-${local.org}-${var.cluster_name}"
  vpc_cidr                 = var.vpc_cidr
  vpc_name                 = "${local.env}-${local.org}-${var.vpc_name}"
  igw_name                 = "${local.env}-${local.org}-${var.igw_name}"
  public_subnet_count      = var.public_subnet_count
  public_subnet_cidrs      = var.public_subnet_cidrs
  public_subnet_name       = "${local.env}-${local.org}-${var.public_subnet_name}"
  private_subnet_count     = var.private_subnet_count
  private_subnet_cidrs     = var.private_subnet_cidrs
  private_subnet_name      = "${local.env}-${local.org}-${var.private_subnet_name}"
  availability_zones       = var.availability_zones
  public_route_table_name  = "${local.env}-${local.org}-${var.public_route_table_name}"
  private_route_table_name = "${local.env}-${local.org}-${var.private_route_table_name}"
  eip_name                 = "${local.env}-${local.org}-${var.eip_name}"
  nat_gateway_name         = "${local.env}-${local.org}-${var.nat_gateway_name}"

  cluster_version           = var.cluster_version
  endpoint_private_access   = var.endpoint_private_access
  endpoint_public_access    = var.endpoint_public_access
  node_group_instance_types = var.node_group_instance_types
  node_group_capacity_type  = var.node_group_capacity_type
  node_group_desired_size   = var.node_group_desired_size
  node_group_max_size       = var.node_group_max_size
  node_group_min_size       = var.node_group_min_size

  vpn_domain                = "${var.vpn_domain}"
  client_cidr_block         = "${var.client_cidr_block}"

}


output "client_key" {
  value     = module.eks.client_key
  sensitive = true
}

output "client_cert" {
  value     = module.eks.client_cert
  sensitive = true
}
