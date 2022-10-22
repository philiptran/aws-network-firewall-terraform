module "firewall" {
  source = "./modules/firewall"
  vpc_id = aws_vpc.inspection_vpc.id
  subnet_ids = aws_subnet.inspection_vpc_firewall_subnet[*].id
  ip_sets = [aws_vpc.app1_vpc.cidr_block, aws_vpc.integration_vpc.cidr_block]
}

module "it_api" {
  source = "./modules/integration_api"
  vpc_id = aws_vpc.integration_vpc.id
  subnet_ids = aws_subnet.integration_vpc_protected_subnet[*].id
  super_cidr_block = var.super_cidr_block
}