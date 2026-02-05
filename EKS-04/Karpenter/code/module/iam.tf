data "aws_caller_identity" "current" {}

locals {
    cluster-name = var.cluster_name 
    account_id = data.aws_caller_identity.current.account_id
    region     = var.aws_region
}


resource "random_integer" "randoem_suffix" {
    min = 1000
    max = 9999
  
}

data "tls_certificate" "eks-certificate" {
  url = aws_eks_cluster.eks[0].identity[0].oidc[0].issuer
}

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




# Karpenter role and policies


data "aws_iam_policy_document" "karpenter_irsa_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks-oidc.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks-oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks-oidc.arn]
    }
  }
}



resource "aws_iam_role" "karpenter_controller" {
  name               = "KarpenterControllerRole-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.karpenter_irsa_assume_role.json
}




// =====add policy to that above role===
resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "KarpenterControllerPolicy-${var.cluster_name}"

  policy = jsonencode({
      "Statement": [
          {
              "Action": [
                  "ssm:GetParameter",
                  "ec2:DescribeImages",
                  "ec2:RunInstances",
                  "ec2:DescribeSubnets",
                  "ec2:DescribeSecurityGroups",
                  "ec2:DescribeLaunchTemplates",
                  "ec2:DescribeInstances",
                  "ec2:DescribeInstanceTypes",
                  "ec2:DescribeInstanceTypeOfferings",
                  "ec2:DeleteLaunchTemplate",
                  "ec2:CreateTags",
                  "ec2:CreateLaunchTemplate",
                  "ec2:CreateFleet",
                  "ec2:DescribeSpotPriceHistory",
                  "pricing:GetProducts"
              ],
              "Effect": "Allow",
              "Resource": "*",
              "Sid": "Karpenter"
          },
          {
              "Action": "ec2:TerminateInstances",
              "Condition": {
                  "StringLike": {
                      "ec2:ResourceTag/karpenter.sh/nodepool": "*"
                  }
              },
              "Effect": "Allow",
              "Resource": "*",
              "Sid": "ConditionalEC2Termination"
          },
          {
              "Effect": "Allow",
              "Action": "iam:PassRole",
              "Resource": "arn:aws:iam::${local.account_id}:role/KarpenterNodeRole-${var.cluster_name}",
              "Sid": "PassNodeIAMRole"
          },
          {
              "Effect": "Allow",
              "Action": "eks:DescribeCluster",
              "Resource": "arn:aws:eks:${local.region}:${local.account_id}:cluster/${var.cluster_name}",
              "Sid": "EKSClusterEndpointLookup"
          },
          {
              "Sid": "AllowScopedInstanceProfileCreationActions",
              "Effect": "Allow",
              "Resource": "*",
              "Action": [
                  "iam:CreateInstanceProfile"
              ],
              "Condition": {
                  "StringEquals": {
                      "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
                      "aws:RequestTag/topology.kubernetes.io/region": "${local.region}"
                  },
                  "StringLike": {
                      "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
                  }
              }
          },
          {
              "Sid": "AllowScopedInstanceProfileTagActions",
              "Effect": "Allow",
              "Resource": "*",
              "Action": [
                  "iam:TagInstanceProfile"
              ],
              "Condition": {
                  "StringEquals": {
                      "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
                      "aws:ResourceTag/topology.kubernetes.io/region": "${local.region}",
                      "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
                      "aws:RequestTag/topology.kubernetes.io/region": "${local.region}"
                  },
                  "StringLike": {
                      "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*",
                      "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
                  }
              }
          },
          {
              "Sid": "AllowScopedInstanceProfileActions",
              "Effect": "Allow",
              "Resource": "*",
              "Action": [
                  "iam:AddRoleToInstanceProfile",
                  "iam:RemoveRoleFromInstanceProfile",
                  "iam:DeleteInstanceProfile"
              ],
              "Condition": {
                  "StringEquals": {
                      "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
                      "aws:ResourceTag/topology.kubernetes.io/region": "${local.region}"
                  },
                  "StringLike": {
                      "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*"
                  }
              }
          },
          {
              "Sid": "AllowInstanceProfileReadActions",
              "Effect": "Allow",
              "Resource": "*",
              "Action": "iam:GetInstanceProfile"
          },
          {
              "Sid": "AllowUnscopedInstanceProfileListAction",
              "Effect": "Allow",
              "Resource": "*",
              "Action": "iam:ListInstanceProfiles"
          }
      ],
      "Version": "2012-10-17"
  })
  
}



resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_attachment" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
  
}



resource "aws_iam_role" "karpenter_node_role" {
  name               = "KarpenterNodeRole-${var.cluster_name}"
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

resource "aws_iam_role_policy_attachment" "karpenter_node_worker" {
    role     = aws_iam_role.karpenter_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
    role     = aws_iam_role.karpenter_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
    role     = aws_iam_role.karpenter_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
    role     = aws_iam_role.karpenter_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# instance profile for Karpenter nodes
resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_node_role.name
}


