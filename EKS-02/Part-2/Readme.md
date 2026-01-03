# **Setting up Private EKS with AWS Client VPN (Terraform)**

**Prerequisites**
- Basic understanding of Terraform
- Watch Part 1, beacuse I have explained everyting in that (Manual setup)

## **Architecture Overview**

![Architecture Diagram](../Part-1/image.png)


```
terraform output -raw client_cert > client.crt
terraform output -raw client_key > client.key
```