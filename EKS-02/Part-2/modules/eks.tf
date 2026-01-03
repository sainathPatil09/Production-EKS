resource "aws_eks_cluster" "eks" {
    name = var.cluster_name
    role_arn = aws_iam_role.eks_cluster_role.arn
    version = var.cluster_version
    
    bootstrap_self_managed_addons = true

    vpc_config {
      subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]
      endpoint_private_access = var.endpoint_private_access
      endpoint_public_access = var.endpoint_public_access
      security_group_ids = [aws_security_group.eks_cluster_sg.id]
    }

    access_config {
      authentication_mode = "API"
      bootstrap_cluster_creator_admin_permissions = true
    }

    tags = {
      "Name" = var.cluster_name
      "Env"  = var.env 
    }
}


resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]

  instance_types = var.node_group_instance_types
  capacity_type = var.node_group_capacity_type

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  update_config {
    max_unavailable = 1
  }

  disk_size = 50
  tags = {
    "Name" = "${var.cluster_name}-node-group"
    "Env"  = var.env 
  }
  tags_all = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"

  }

  depends_on = [ aws_eks_cluster.eks ]
}