locals {
  cluster_name = var.cluster_name
}

resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr
    instance_tenancy = "default"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        "Name" = var.vpc_name
         "Env"  = var.env 
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        "Name" = var.igw_name
        "Env"  = var.env 
        "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    }
    depends_on = [ aws_vpc.vpc ]
}


resource "aws_subnet" "public_subnet" {
    count = var.public_subnet_count
    vpc_id = aws_vpc.vpc.id
    cidr_block = element(var.public_subnet_cidrs, count.index)
    availability_zone = element(var.availability_zones, count.index)
    map_public_ip_on_launch = true

    tags = {
      "Name" = "${var.public_subnet_name}-${count.index + 1}"
      "Env"  = var.env
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
      "kubernetes.io/role/elb" = "1"
    }

    depends_on = [ aws_vpc.vpc ]

}

resource "aws_subnet" "private_subnet" {
    count = var.private_subnet_count
    vpc_id = aws_vpc.vpc.id
    cidr_block = element(var.private_subnet_cidrs, count.index)
    availability_zone = element(var.availability_zones, count.index)
    map_public_ip_on_launch = false

    tags = {
      "Name" = "${var.private_subnet_name}-${count.index + 1}"
      "Env"  = var.env
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    }

    depends_on = [ aws_vpc.vpc ]
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
      "Name" = "${var.public_route_table_name}"
      "Env"  = var.env  
    }

    depends_on = [ aws_vpc.vpc ]
}

resource "aws_route_table_association" "public_subnet_route_table_association" {
    count = var.public_subnet_count
    subnet_id = aws_subnet.public_subnet[count.index].id
    route_table_id = aws_route_table.public_route_table.id

    depends_on = [ aws_vpc.vpc, aws_subnet.public_subnet, aws_route_table.public_route_table ]
}


# =======NAT GATEWAY====================
resource "aws_eip" "nat_eip" {
  count = var.private_subnet_count
  domain = "vpc"
  
  tags = {
    "Name" = var.eip_name 
  }
  depends_on = [ aws_vpc.vpc ]
}


resource "aws_nat_gateway" "nat_gw" {
 count = var.private_subnet_count
 allocation_id = aws_eip.nat_eip[count.index].id
 subnet_id = aws_subnet.public_subnet[count.index].id

  tags = {
      Name = var.nat_gateway_name
    }
  
 depends_on = [ aws_vpc.vpc, aws_eip.nat_eip ]
}



resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.vpc.id
    count = var.private_subnet_count
    
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
    }

    tags = {
      "Name" = var.private_route_table_name
      "Env"  = var.env  
    }

    depends_on = [ aws_vpc.vpc ]
}

resource "aws_route_table_association" "private_subnet_route_table_association" {
    count = var.private_subnet_count
    subnet_id = aws_subnet.private_subnet[count.index].id
    route_table_id = aws_route_table.private_route_table[count.index].id

    depends_on = [ aws_vpc.vpc, aws_subnet.private_subnet, aws_route_table.private_route_table ]
}


