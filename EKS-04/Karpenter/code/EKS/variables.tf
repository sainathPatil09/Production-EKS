variable "aws_region" {}

variable "cluster_name" {}
variable "vpc_cidr_block" {}
variable "vpc_name" {}
variable "env" {}
variable "igw_name" {}
variable "public_subnet_count" {}
variable "public_subnet_cidr_block" {
  type = list(string)
}
variable "availability_zones" {
  type = list(string)
}
variable "public_subnet_name" {}
variable "private_subnet_count" {}
variable "private_subnet_cidr_block" {
  type = list(string)
}

variable "private_subnet_name" {}
variable "public_route_table_name" {}
variable "private_route_table_name" {}
variable "eip_name" {}
variable "nat_gateway_name" {}
variable "eks-sg" {}

#IAM
variable "create_eks_cluster_role" {
  type = bool
}
variable "create_eks_nodegroup_role" {
  type = bool
}

# EKS
variable "create_eks_cluster" {}
variable "kubernetes_version" {}
variable "endpoint_private_access" {}
variable "endpoint_public_access" {}
variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))
}

variable "instance_types" {}
variable "desired_capacity" {}
variable "min_capacity" {}
variable "max_capacity" {}