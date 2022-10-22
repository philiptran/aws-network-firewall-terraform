data "terraform_remote_state" "parent" {
  backend = "local"
  config = {
    path = "../../terraform.tfstate"
  }
}

data "dns_a_record_set" "app_nlb_ips" {
  host = data.terraform_remote_state.parent.outputs.app_nlb_dns_name
}

locals {
  ingressegress_vpc_id = data.terraform_remote_state.parent.outputs.ingressegress_vpc_id
  ingressegress_vpc_public_subnet_ids = data.terraform_remote_state.parent.outputs.ingressegress_vpc_public_subnet_ids
  app_nlb_ips = toset(data.dns_a_record_set.app_nlb_ips.addrs)
}
