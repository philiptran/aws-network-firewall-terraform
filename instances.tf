// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_security_group" "app1_vpc_endpoint_sg" {
  name        = "app1-vpc/sg-ssm-ec2-endpoints"
  description = "Allow TLS inbound traffic for SSM/EC2 endpoints"
  vpc_id      = aws_vpc.app1_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.app1_vpc.cidr_block]
  }
  tags = {
    Name = "app1-vpc/sg-ssm-ec2-endpoints"
  }
}

resource "aws_security_group" "app1_vpc_host_sg" {
  name        = "app1-vpc/sg-host"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = aws_vpc.app1_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.app1_vpc.cidr_block, aws_vpc.integration_vpc.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "app1-vpc/sg-host"
  }
}

resource "aws_security_group" "integration_vpc_host_sg" {
  name        = "integration-vpc/sg-host"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = aws_vpc.integration_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.app1_vpc.cidr_block, aws_vpc.integration_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "integration-vpc/sg-host"
  }
}

resource "aws_security_group" "integration_vpc_endpoint_sg" {
  name        = "integration-vpc/sg-ssm-ec2-endpoints"
  description = "Allow TLS inbound traffic for SSM/EC2 endpoints"
  vpc_id      = aws_vpc.integration_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.integration_vpc.cidr_block]
  }
  tags = {
    Name = "integration-vpc/sg-ssm-ec2-endpoints"
  }
}

resource "aws_vpc_endpoint" "app1_vpc_ssm_endpoint" {
  vpc_id            = aws_vpc.app1_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.app1_vpc_endpoint_subnet[*].id
  security_group_ids = [
    aws_security_group.app1_vpc_endpoint_sg.id,
  ]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "app1_vpc_ssm_messages_endpoint" {
  vpc_id            = aws_vpc.app1_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.app1_vpc_endpoint_subnet[*].id
  security_group_ids = [
    aws_security_group.app1_vpc_endpoint_sg.id,
  ]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "app1_vpc_ec2_messages_endpoint" {
  vpc_id            = aws_vpc.app1_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.app1_vpc_endpoint_subnet[*].id
  security_group_ids = [
    aws_security_group.app1_vpc_endpoint_sg.id,
  ]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "integration_vpc_ssm_endpoint" {
  vpc_id            = aws_vpc.integration_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.integration_vpc_endpoint_subnet[*].id
  security_group_ids = [
    aws_security_group.integration_vpc_endpoint_sg.id,
  ]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "integration_vpc_ssm_messages_endpoint" {
  vpc_id            = aws_vpc.integration_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.integration_vpc_endpoint_subnet[*].id
  security_group_ids = [
    aws_security_group.integration_vpc_endpoint_sg.id,
  ]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "integration_vpc_ec2_messages_endpoint" {
  vpc_id            = aws_vpc.integration_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.integration_vpc_endpoint_subnet[*].id
  security_group_ids = [
    aws_security_group.integration_vpc_endpoint_sg.id,
  ]
  private_dns_enabled = true
}

resource "aws_iam_role" "instance_role" {
  name               = "session-manager-instance-profile-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "session-manager-instance-profile"
  role = aws_iam_role.instance_role.name
}


resource "aws_iam_role_policy_attachment" "instance_role_policy_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_instance" "app1_vpc_host" {
  ami                    = data.aws_ami.amazon-linux-2.id
  subnet_id              = aws_subnet.app1_vpc_protected_subnet[0].id
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.app1_vpc_host_sg.id]
  tags = {
    Name = "app1-vpc/host"
  }
  user_data = file("install-nginx.sh")
}

resource "aws_instance" "integration_vpc_host" {
  ami                    = data.aws_ami.amazon-linux-2.id
  subnet_id              = aws_subnet.integration_vpc_protected_subnet[0].id
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.integration_vpc_host_sg.id]
  tags = {
    Name = "integration-vpc/host"
  }
  user_data = file("install-nginx.sh")
}

output "app1_vpc_host_ip" {
  value = aws_instance.app1_vpc_host.private_ip
}

output "integration_vpc_host_ip" {
  value = aws_instance.integration_vpc_host.private_ip
}
