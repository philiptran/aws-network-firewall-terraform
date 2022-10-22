resource "aws_vpc" "integration_vpc" {
  cidr_block           = local.integration_vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "integration-vpc"
  }
}

resource "aws_subnet" "integration_vpc_protected_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.integration_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.integration_vpc_cidr, 4, 3 + count.index)
  tags = {
    Name = "integration-vpc/${data.aws_availability_zones.available.names[count.index]}/protected-subnet"
  }
}

resource "aws_subnet" "integration_vpc_endpoint_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.integration_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.integration_vpc_cidr, 4, 6 + count.index)

  tags = {
    Name = "integration-vpc/${data.aws_availability_zones.available.names[count.index]}/endpoint-subnet"
  }
}

resource "aws_subnet" "integration_vpc_tgw_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.integration_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.integration_vpc_cidr, 4, count.index)
  tags = {
    Name = "integration-vpc/${data.aws_availability_zones.available.names[count.index]}/tgw-subnet"
  }
}

resource "aws_route_table" "integration_vpc_route_table" {
  vpc_id = aws_vpc.integration_vpc.id
  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  tags = {
    Name = "integration-vpc/route-table"
  }
}

resource "aws_route_table_association" "integration_vpc_route_table_association" {
  count          = length(aws_subnet.integration_vpc_protected_subnet[*])
  subnet_id      = aws_subnet.integration_vpc_protected_subnet[count.index].id
  route_table_id = aws_route_table.integration_vpc_route_table.id
}