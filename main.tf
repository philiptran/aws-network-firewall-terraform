module "ingress_alb" {
  source = "./modules/ingress_alb"
  vpc_id = aws_vpc.ingressegress_vpc.id
  subnet_ids = aws_subnet.ingressegress_vpc_public_subnet[*].id
  app_nlb_dns_name = aws_lb.app_nlb.dns_name
}

module "it_api" {
  source = "./modules/integration_api"
  vpc_id = aws_vpc.integration_vpc.id
  subnet_ids = aws_subnet.integration_vpc_protected_subnet[*].id
  super_cidr_block = var.super_cidr_block
}