variable "super_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

locals {
  app1_vpc_cidr    = cidrsubnet(var.super_cidr_block, 8, 3)
  integration_vpc_cidr    = cidrsubnet(var.super_cidr_block, 8, 2)
  inspection_vpc_cidr = cidrsubnet(var.super_cidr_block, 8, 1)
  ingressegress_vpc_cidr = cidrsubnet(var.super_cidr_block, 8, 0)
}
