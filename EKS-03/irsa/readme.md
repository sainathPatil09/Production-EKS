eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve


**Create and associate IAM Role**
   eksctl create iamserviceaccount \
--name my-service-account \
--namespace default \
--cluster eks-demo \
--role-name s3-access-role \
--region ap-south-1 \
--attach-policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
--approve