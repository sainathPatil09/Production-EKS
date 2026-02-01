locals {
    cluster-name = var.cluster_name 
    account_id = data.aws_caller_identity.current.account_id
    region     = var.aws_region
}


data "aws_caller_identity" "current" {}

data "tls_certificate" "eks-certificate" {
  url = aws_eks_cluster.eks[0].identity[0].oidc[0].issuer
}

resource "random_integer" "randoem_suffix" {
    min = 1000
    max = 9999
  
}


#  creating eks cluster role and attaching policies
resource "aws_iam_role" "eks_cluster_role" {
    count = var.create_eks_cluster_role ? 1 : 0
    name = "${local.cluster-name}-eks-cluster-role-${random_integer.randoem_suffix.result}"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            },
        ]
    })
}


resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy_attachment" {
    count = var.create_eks_cluster_role ? 1 : 0
    role     = aws_iam_role.eks_cluster_role[count.index].name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  
}



# creating eks nodegroup role and attaching policies
resource "aws_iam_role" "eks_nodegroup_role" {
    count = var.create_eks_nodegroup_role ? 1 : 0
    name = "${local.cluster-name}-eks-nodegroup-role-${random_integer.randoem_suffix.result}"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            },
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_role_policy_attachment" {
    count = var.create_eks_nodegroup_role ? 1: 0
    role     = aws_iam_role.eks_nodegroup_role[count.index].name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks-cni-policy-attachment" {
    count = var.create_eks_nodegroup_role ? 1: 0
    role     = aws_iam_role.eks_nodegroup_role[count.index].name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  
}

resource "aws_iam_role_policy_attachment" "ecr-readonly-policy-attachment" {
    count = var.create_eks_nodegroup_role ? 1: 0
    role     = aws_iam_role.eks_nodegroup_role[count.index].name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  
}

resource "aws_iam_role_policy_attachment" "ebs-csi-policy-attachment" {
    count = var.create_eks_nodegroup_role ? 1: 0
    role     = aws_iam_role.eks_nodegroup_role[count.index].name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  
}


#  creating eks oidc role and attaching policies
data "aws_iam_policy_document" "eks_oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks-oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:aws-test"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks-oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks-oidc-role" {
    assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_policy.json
    name = "eks-oidc"
}

resource "aws_iam_policy" "eks-oidc-policy" {
  name = "test-policy"

  policy = jsonencode({
    Statement = [{
      Action = [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "*"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}


resource "aws_iam_role_policy_attachment" "eks-oidc-policy-attachment" {
    role       = aws_iam_role.eks-oidc-role.name
    policy_arn = aws_iam_policy.eks-oidc-policy.arn
  
}




