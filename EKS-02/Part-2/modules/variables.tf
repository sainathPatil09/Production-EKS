variable "cluster_name" {}
variable "vpc_cidr" {}
variable "vpc_name" {}
variable "env" {}
variable "igw_name" {}

variable "public_subnet_count" {}
variable "public_subnet_cidrs" { type = list(string) }
variable "public_subnet_name" {}
variable "private_subnet_count" {}
variable "private_subnet_cidrs" { type = list(string) }
variable "private_subnet_name" {}
variable "availability_zones" { type = list(string) }
variable "public_route_table_name" {}
variable "private_route_table_name" {}

variable "eip_name" {}
variable "nat_gateway_name" {}

variable "cluster_version" {}
variable "endpoint_private_access" { type = bool }
variable "endpoint_public_access" { type = bool }
variable "node_group_instance_types" { type = list(string) }
variable "node_group_capacity_type" {}
variable "node_group_desired_size" { type = number }
variable "node_group_max_size" { type = number }
variable "node_group_min_size" { type = number }


variable "vpn_domain" {}
variable "client_cidr_block" {}