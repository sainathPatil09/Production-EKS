# **Securing Amazon EKS: RBAC & IRSA (Hands-On Demo)**

This repository demonstrates how to properly secure an Amazon EKS cluster using:

- Kubernetes **RBAC** for human access control

- **IAM Roles for Service Accounts (IRSA)** for pod-level AWS permissions

The demo shows real security failures first, then fixes them using least-privilege best practices.

**YouTube Video:** [Watch](https://google.com)


## **What You Will Learn**

By going through this demo, you will understand:

- Why EKS is not secure by default

- How IAM authentication and Kubernetes RBAC work together

- How to restrict developers to namespace-level access

- Why pods should never use node IAM roles

- How IRSA isolates AWS permissions per workload

- How to implement least-privilege security in production EKS clusters

---


**Key Security Principles**

- IAM handles authentication

- RBAC handles authorization inside Kubernetes

- IRSA handles AWS permissions for pods

- Node IAM roles should have zero application permissions


### **RBAC Diagram**
![Architecture Diagram](.\rbac\rbac.png)

### **RBAC (Role Based Access Control)**
Imagine Kubernetes as a big office building with many rooms (resources like pods, services, secrets, deployments etc.). RBAC is like the security system that decides:

- Who can enter which rooms (authentication)
- What they can do in those rooms (authorization)

#### **Key Components of RBAC**
#### **1. Subjects (Who is asking?)**
Think of subjects as people who are accessing EKS
- **USERS**
  - Indiviual entity/user (ex: IAM user)
- **Group**
  - Group of users

#### **2. Resources (What are they trying to access?)**
```
# Common Kubernetes Resources
pods          
services      
secrets       
configmaps    
deployments   
namespaces    
nodes 
```

#### **3. Verbs (What do they want to do?)**
```
# Read Operations (Safe)
get     
list    
watch   

# Write Operations (More Risky)
create  
update  
patch   

# Delete Operations (Most Risky)
delete  
```

#### **4. Roles (Permissions given to Subjects)**
- Roles are `namespace` scoped
- Role defined in one `namespace` will not have any effect other namespace

#### **5. ClusterRole**
- Same as Roles but Permissions are given Cluster wide
- If any subject given permission with ClusterRole, can perform actions accros namespace
- Avoid using clusterRole until it is neccessary to use

#### **6. RoleBinding**
- Subject + Role = RoleBinding
- using RoleBinding we give role to subject

#### **7. ClusterRoleBinding**
- Subject + ClusterRole = ClusterRoleBinding
- same as Role but applied for ClusterRole


---

### **IRSA Diagram**

![Architecture Diagram](irsa\image.png)

By default:

- Pods inherit node IAM role permissions

- A compromised pod can access all AWS resources

**IRSA stands for IAM Roles for Service Accounts.**
- It’s an AWS mechanism that lets Kubernetes pods in EKS securely assume IAM roles using Kubernetes service accounts, instead of sharing node-level credentials.

What problem does IRSA solve?

Without IRSA in EKS:

- Pods inherit IAM permissions of the worker node (EC2 role)

- Every pod on that node gets the same AWS permissions

- This violates least privilege

**How IRSA works (simple flow)**

- EKS cluster has an OIDC identity provider enabled

- You create:

  - A Kubernetes ServiceAccount

  - IAM Role with required AWS permissions
 
- The IAM role’s trust policy allows assumption via the cluster’s OIDC provider

- The ServiceAccount is annotated with the IAM role ARN

- Pod uses this ServiceAccount

- AWS STS issues temporary credentials to the pod

- Pod now has only the permissions it needs

**Why use IRSA with EKS? (Key benefits)**
- Pod-level IAM permissions (Least Privilege)
- No AWS credentials stored in pods
- Better security isolation
- Easier auditing & compliance
- Supports fine-grained access control

IRSA allows Kubernetes pods in EKS to assume IAM roles securely using service accounts, enabling least-privilege, credential-free, pod-level access to AWS services.




**Install AWS CLI**
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
```

**Install kubectl**
```
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
kubectl version --short --client
```

**Install EKSCTL**
```
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

**Command to create Cluster**
```
eksctl create cluster --name=eks-demo \
                      --region=ap-south-1 \
                      --version=1.34 \
                      --without-nodegroup
```

**Command to add node group**
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
<!-- 
```
aws sts get-caller-identity --profile intern-eks


eksctl delete cluster --name=eks-demo --region=ap-south-1


aws eks update-kubeconfig --region ap-south-1 --name eks-demo


aws eks list-access-entries --cluster-name eks-demo


aws eks create-access-entry --cluster-name eks-demo --principal-arn <role> --type STANDARD --user Viewers --kubernetes-groups Viewers


aws eks list-associated-access-policies --cluster-name eks-demo --principal-arn arn:aws:iam::xxxx:user/wiings


aws eks disassociate-access-policy --cluster-name my-cluster --principal-arn arn:aws:iam::111122223333:role/my-role \
    --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy

```


aws sts assume-role \
  --role-arn arn:aws:iam::xxxx:role/EKS-Intern-Role \
  --role-session-name intern-session


export AWS_ACCESS_KEY_ID="ASIA27DAJS6UQAX57NJ6UQAX57NJ6"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"

setx AWS_ACCESS_KEY_ID "value"
setx AWS_SECRET_ACCESS_KEY "value"
setx AWS_SESSION_TOKEN "value"


aws eks update-kubeconfig \
  --region ap-south-1 \
  --name eks-demo \
  --role-arn arn:aws:iam::xxxx:role/EKS-Intern-Role


IRSA





   eksctl create iamserviceaccount \
--name my-service-account \
--namespace default \
--cluster eks-demo \
--role-name s3-access-role \
--region ap-south-1 \
--attach-policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
--approve


kubectl get sa my-service-account -o yaml -->

https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html


