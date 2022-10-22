variable "super_cidr_block" {
  default = "Super CIDR block for all VPCs"
  type    = string
}

variable "vpc_id" {
  description = "VPC id of the integration vpc"
  type = string
}

variable "subnet_ids" {
  description = "Subnet ids of the integration tier"
  type = list  
}

data "aws_region" "current" {}