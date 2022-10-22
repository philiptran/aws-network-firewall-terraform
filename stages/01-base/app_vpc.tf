resource "aws_vpc" "app1_vpc" {
  cidr_block           = local.app1_vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "app1-vpc"
  }
}

resource "aws_subnet" "app1_vpc_protected_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.app1_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.app1_vpc_cidr, 4, 3 + count.index)

  tags = {
    Name = "app1-vpc/${data.aws_availability_zones.available.names[count.index]}/protected-subnet"
  }
}

resource "aws_subnet" "app1_vpc_endpoint_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.app1_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.app1_vpc_cidr, 4, 6 + count.index)

  tags = {
    Name = "app1-vpc/${data.aws_availability_zones.available.names[count.index]}/endpoint-subnet"
  }
}

resource "aws_subnet" "app1_vpc_tgw_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.app1_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.app1_vpc_cidr, 4, count.index)

  tags = {
    Name = "app1-vpc/${data.aws_availability_zones.available.names[count.index]}/tgw-subnet"
  }
}


resource "aws_route_table" "app1_vpc_route_table" {
  vpc_id = aws_vpc.app1_vpc.id
  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  tags = {
    Name = "app1-vpc/route-table"
  }
}

resource "aws_route_table_association" "app1_vpc_route_table_association" {
  count          = length(aws_subnet.app1_vpc_protected_subnet[*])
  subnet_id      = aws_subnet.app1_vpc_protected_subnet[count.index].id
  route_table_id = aws_route_table.app1_vpc_route_table.id
}
