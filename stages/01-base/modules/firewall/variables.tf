variable "vpc_id" {
  description = "ID of VPC to deploy the firewall endpoints"
  type = string
}

variable "subnet_ids" {
  description = "IDs of firewall subnets in the Inspection VPC"
  type = list
}
variable "ip_sets" {
  description = "IP sets for firewall rule group"
  type = list
}
