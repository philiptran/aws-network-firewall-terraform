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
    cidr_blocks = [aws_vpc.ingressegress_vpc.cidr_block, aws_vpc.app1_vpc.cidr_block, aws_vpc.integration_vpc.cidr_block]
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

# Create an instance in integration VPC for "ping" tests
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

# Create an internal NLB to front the EC2 instances in Application VPC
resource "aws_lb" "app_nlb" {
  name               = "app-nlb"
  load_balancer_type = "network"
  subnets            = aws_subnet.app1_vpc_protected_subnet[*].id
  enable_cross_zone_load_balancing = true
  internal = true
}
resource "aws_lb_listener" "app_nlb_listener" {
  load_balancer_arn = aws_lb.app_nlb.arn
  protocol          = "TCP"
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_nlb_targetgroup.arn
  }
}

resource "aws_lb_target_group" "app_nlb_targetgroup" {
  name = "app-nlb-tg"
  port = 80
  protocol = "TCP"
  vpc_id = aws_vpc.app1_vpc.id
  depends_on = [aws_lb.app_nlb]
  lifecycle {
    create_before_destroy = true
  }
  # IP-based target type
  target_type = "ip"

  stickiness {
    enabled = true
    type = "source_ip"
  }
}
resource "aws_lb_target_group_attachment" "app_nlb_tg_targets" {
  target_group_arn  = aws_lb_target_group.app_nlb_targetgroup.arn
  target_id         = aws_instance.app1_vpc_host.private_ip
  port              = 80
}

# Get IP addresses of NLB 
data "dns_a_record_set" "app_nlb_ips" {
  host = aws_lb.app_nlb.dns_name
}
locals {
  app_nlb_ips = toset(data.dns_a_record_set.app_nlb_ips.addrs)
}

#TODO: create a autoscaling group for EC2 instances
#resource "aws_autoscaling_attachment" "app_nlb_targetgroup_targets" {
#  autoscaling_group_name = ...
#  alb_target_group_arn = aws_lb_target_group.app_nlb_targetgroup.arn
#}

