// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_vpc" "ingressegress_vpc" {
  cidr_block       = local.ingressegress_vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "ingressegress-vpc"
  }
}

resource "aws_subnet" "ingressegress_vpc_public_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.ingressegress_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.ingressegress_vpc_cidr, 8, 10 + count.index)
  depends_on              = [aws_internet_gateway.ingressegress_vpc_igw]
  tags = {
    Name = "ingressegress-vpc/${data.aws_availability_zones.available.names[count.index]}/public-subnet"
  }
}

resource "aws_internet_gateway" "ingressegress_vpc_igw" {
  vpc_id = aws_vpc.ingressegress_vpc.id
  tags = {
    Name = "ingressegress-vpc/internet-gateway"
  }
}

resource "aws_eip" "ingressegress_vpc_nat_gw_eip" {
  count = length(data.aws_availability_zones.available.names)
}

resource "aws_nat_gateway" "ingressegress_vpc_nat_gw" {
  count         = length(data.aws_availability_zones.available.names)
  depends_on    = [aws_internet_gateway.ingressegress_vpc_igw, aws_subnet.ingressegress_vpc_public_subnet]
  allocation_id = aws_eip.ingressegress_vpc_nat_gw_eip[count.index].id
  subnet_id     = aws_subnet.ingressegress_vpc_public_subnet[count.index].id
  tags = {
    Name = "ingressegress-vpc/${data.aws_availability_zones.available.names[count.index]}/nat-gateway"
  }
}



resource "aws_subnet" "ingressegress_vpc_tgw_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.ingressegress_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.ingressegress_vpc_cidr, 8, 30 + count.index)
  tags = {
    Name = "ingressegress-vpc/${data.aws_availability_zones.available.names[count.index]}/tgw-subnet"
  }
}

resource "aws_route_table" "ingressegress_vpc_tgw_subnet_route_table" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.ingressegress_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ingressegress_vpc_nat_gw[count.index].id
  }
  route {
    cidr_block         = var.super_cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  tags = {
    Name = "ingressegress-vpc/${data.aws_availability_zones.available.names[count.index]}/tgw-subnet-route-table"
  }
}

resource "aws_route_table_association" "ingressegress_vpc_tgw_subnet_route_table_association" {
  count          = length(data.aws_availability_zones.available.names)
  route_table_id = aws_route_table.ingressegress_vpc_tgw_subnet_route_table[count.index].id
  subnet_id      = aws_subnet.ingressegress_vpc_tgw_subnet[count.index].id
}

resource "aws_route_table" "ingressegress_vpc_public_subnet_route_table" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.ingressegress_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ingressegress_vpc_igw.id
  }
  route {
    cidr_block = var.super_cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  tags = {
    Name = "ingressegress-vpc/${data.aws_availability_zones.available.names[count.index]}/public-subnet-route-table"
  }
}

resource "aws_route_table_association" "ingressegress_vpc_public_subnet_route_table_association" {
  count          = length(data.aws_availability_zones.available.names)
  route_table_id = aws_route_table.ingressegress_vpc_public_subnet_route_table[count.index].id
  subnet_id      = aws_subnet.ingressegress_vpc_public_subnet[count.index].id
}
