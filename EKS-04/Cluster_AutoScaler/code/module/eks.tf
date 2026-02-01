resource "aws_eks_cluster" "eks" {
    count = var.create_eks_cluster ? 1 : 0
    name = var.cluster_name
    role_arn = aws_iam_role.eks_cluster_role[count.index].arn
    version = var.kubernetes_version

    vpc_config {
        subnet_ids =  [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]
        endpoint_private_access = var.endpoint_private_access
        endpoint_public_access = var.endpoint_public_access
        security_group_ids = [aws_security_group.eks-cluster-sg.id]
    }

    access_config {
        authentication_mode = "API"
        bootstrap_cluster_creator_admin_permissions = true
    }

    tags = {
        Name = var.cluster_name
        Env  = var.env
    }

}


resource "aws_iam_openid_connect_provider" "eks-oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-certificate.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.eks-certificate.url
}


resource "aws_eks_addon" "eks-addons" {
    for_each = { for idx, addon in var.addons : idx => addon }
    cluster_name = aws_eks_cluster.eks[0].name
    addon_name   = each.value.name
    addon_version = each.value.version

    depends_on = [ aws_eks_node_group.ondemand-node ]
}


resource "aws_eks_node_group" "ondemand-node" {
    cluster_name = aws_eks_cluster.eks[0].name
    node_group_name = "${var.cluster_name}-ondemand-node-group"
    node_role_arn = aws_iam_role.eks_nodegroup_role[0].arn

    subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]

    scaling_config {
      desired_size = var.desired_capacity
      min_size     = var.min_capacity
      max_size     = var.max_capacity
    }

    instance_types = var.instance_types
    capacity_type  = "ON_DEMAND"

    labels = {
      type = "on-demand"
    }

    update_config {
      max_unavailable = 1
    }


    tags = {
      "Name" = "${var.cluster_name}-ondemand-nodes"
    }

    tags_all = {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }

    depends_on = [ aws_eks_cluster.eks ]
}