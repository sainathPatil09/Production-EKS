```
eksctl create cluster --name=eks-demo \
                      --region=ap-south-1 \
                      --version=1.34 \
                      --without-nodegroup
```

```
eksctl create nodegroup --cluster=eks-demo \
                       --region=ap-south-1 \
                       --name=demo-ng \
                       --node-type=t2.medium \
                       --nodes=1 \
                       --nodes-min=1 \
                       --nodes-max=1 \
                       --node-volume-size=25 
```


**Trust policy for role**
```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "Statement1",
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::xxxx:root"
			},
			"Action": "sts:AssumeRole",
			"Condition": {
				"ArnLike": {
					"aws:PrincipalArn": "arn:aws:iam::xxxx:user/intern-*"
				}
			}
		}
	]
}
```

attach policy to that role
- AmazonEKSClusterPolicy

**IAM Policy to the Group**
- we attach this policy beacuse users can easily assume that role
- this is custom policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:aws:iam::xxx:role/EKS-Intern-Role"
            ]
        }
    ]
}
```

**lets create EKS Access Entry of Role**\
```
aws eks create-access-entry --cluster-name eks-demo --principal-arn <role> --type STANDARD --user Interns --kubernetes-groups Interns-Group

aws eks list-access-entries --cluster-name eks-demo

aws eks update-kubeconfig --region ap-south-1 --name eks-demo --profile
```

lets confugure Intern users

```
aws configure --profile

cat .aws/config

vim .aws/config

[profile intern-eks]
role_arn = arn:aws:iam::xxxx:role/EKS-Intern-Role
source_profile = <profile>
```