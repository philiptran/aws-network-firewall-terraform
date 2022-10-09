variable "super_cidr_block" {
  type    = string
  default = "10.0.0.0/8"
}

locals {
  app1_vpc_cidr    = cidrsubnet(var.super_cidr_block, 8, 10)
  integration_vpc_cidr    = cidrsubnet(var.super_cidr_block, 8, 11)
  inspection_vpc_cidr = cidrsubnet(var.super_cidr_block, 8, 255)
  ingressegress_vpc_cidr = cidrsubnet(var.super_cidr_block, 8, 100)
}
