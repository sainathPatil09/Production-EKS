env                       = "dev"
aws_region                = "ap-south-1"
cluster_name              = "eks-demo"
vpc_cidr_block            = "10.16.0.0/16"
vpc_name                  = "eks-vpc"
igw_name                  = "eks-igw"
public_subnet_count       = 2
public_subnet_cidr_block  = ["10.16.0.0/20", "10.16.16.0/20"]
availability_zones        = ["ap-south-1a", "ap-south-1b"]
public_subnet_name        = "eks-public-subnet"
private_subnet_count      = 2
private_subnet_cidr_block = ["10.16.128.0/20", "10.16.144.0/20"]
private_subnet_name       = "eks-private-subnet"
public_route_table_name   = "eks-public-rt"
private_route_table_name  = "eks-private-rt"
eip_name                  = "eks-eip"
nat_gateway_name          = "eks-ngw"
eks-sg                    = "seks-sg"

create_eks_cluster_role   = true
create_eks_nodegroup_role = true
create_eks_cluster        = true
kubernetes_version        = "1.34"
endpoint_private_access   = true
endpoint_public_access    = false


instance_types   = ["t3.medium"]
desired_capacity = 1
min_capacity     = 1
max_capacity     = 2

addons = [
  {
    name    = "vpc-cni",
    version = "v1.20.0-eksbuild.1"
  },
  {
    name    = "coredns"
    version = "v1.12.2-eksbuild.4"
  },
  {
    name    = "kube-proxy"
    version = "v1.33.0-eksbuild.2"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.46.0-eksbuild.1"
  }
  # Add more addons as needed
]