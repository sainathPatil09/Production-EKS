data "aws_key_pair" "key_pair" {
  key_name = var.key_name
}

resource "aws_instance" "public_ec2" {
  ami  = var.ami_id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_subnet[0].id
  associate_public_ip_address = true
  key_name = data.aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_public_ec2.id]

  user_data = <<-EOF
   #!/bin/bash

    set -e  # Exit immediately if a command fails

    echo "=== Updating system ==="
    sudo apt update -y

    echo "=== Installing required packages ==="
    sudo apt install -y curl unzip

    echo "=== Installing AWS CLI v2 ==="
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -o awscliv2.zip
    sudo ./aws/install

    echo "AWS CLI version:"
    aws --version

    echo "=== Installing kubectl ==="
    curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

    echo "kubectl version:"
    kubectl version --short --client

    echo "=== Installing eksctl ==="
    curl --silent --location \
    "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
    | tar xz -C /tmp

    sudo mv /tmp/eksctl /usr/local/bin/

    echo "eksctl version:"
    eksctl version

    echo "=== Cleanup ==="
    rm -rf aws awscliv2.zip

    echo "=== Installation completed successfully ==="
    EOF

  tags = {
    Name = "Bastion-Host"
  }
}




resource "aws_security_group" "sg_public_ec2" {
  name        = "sg_public_ec2"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress{
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}