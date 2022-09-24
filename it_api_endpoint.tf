resource "aws_security_group" "api_endpoint_sg" {
  name = "api_endpoint_sg"
  description = "Allow HTTPS inbound traffic"
  vpc_id = aws_vpc.spoke_vpc_b.id
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.spoke_vpc_b.cidr_block,aws_vpc.spoke_vpc_a.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "api_endpoint_sg"
  }
}

resource "aws_vpc_endpoint" "api_gateway_endpoint" {
  vpc_id = aws_vpc.spoke_vpc_b.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  private_dns_enabled = true
  subnet_ids = [for s in aws_subnet.spoke_vpc_b_protected_subnet : s.id]
  security_group_ids = [aws_security_group.api_endpoint_sg.id]
  vpc_endpoint_type = "Interface"
  tags = {
    Name = "api_gateway_endpoint"
  }
}
