variable "vpc_id" {
  description = "Ingress/Egress VPC ID for the ALB's targets"
  type = string
}
variable "subnet_ids" {
  type = list
  description = "IDs of public subnets in Ingress/Ggress VPC"
}

variable "app_nlb_dns_name" {
  type = string
  description = "DNS name of the NLB in the Application VPC"
}
