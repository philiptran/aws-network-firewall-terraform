# Create ALB in Ingress/Egress VPC with target group pointing to NLB in the Application VPC
resource "aws_security_group" "ingress_alb_sg" {
  name        = "ingress_alb_security_group"
  description = "Ingress ALB security group"
  vpc_id      = local.ingressegress_vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ingressegress-vpc/ingress-alb-sg"
  }
}
resource "aws_alb" "ingress_alb" {
  name            = "ingress-alb"
  security_groups = [aws_security_group.ingress_alb_sg.id]
  subnets         = local.ingressegress_vpc_public_subnet_ids
  tags = {
    Name = "ingressegress-vpc/ingress-alb"
  }
}
resource "aws_alb_target_group" "ingress_alb_tg" {
  name     = "ingress-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.ingressegress_vpc_id
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/"
    port = 80
  }
  target_type = "ip"
}
resource "aws_alb_listener" "ingress_alb_listener_http" {
  load_balancer_arn = aws_alb.ingress_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.ingress_alb_tg.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "ingress_alb_tg_targets" {
  for_each = local.app_nlb_ips
  target_id         = each.value
  target_group_arn  = aws_alb_target_group.ingress_alb_tg.arn
  port              = 80
  availability_zone = "all"
}
