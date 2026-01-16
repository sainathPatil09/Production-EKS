eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve

kubectl get sa my-service-account -o yaml


**Create and associate IAM Role**

eksctl create iamserviceaccount \
--name my-service-account \
--namespace default \
--cluster eks-demo \
--role-name s3-access-role \
--region ap-south-1 \
--attach-policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
--approve





{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::xxxx:oidc-provider/oidc.eks.ap-south-1.amazonaws.com/id/0E8C72089A6F47ADD982E909A331381F"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.ap-south-1.amazonaws.com/id/0E8C72089A6F47ADD982E909A331381F:sub": "system:serviceaccount:default:my-service-account",
                    "oidc.eks.ap-south-1.amazonaws.com/id/0E8C72089A6F47ADD982E909A331381F:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}


 kubectl api-resources 

 /var/run/secrets/eks.amazonaws.com/serviceaccount/token

 kubectl exec -it aws-cli -- /bin/sh
