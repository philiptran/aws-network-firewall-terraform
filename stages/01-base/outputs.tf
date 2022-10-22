output "firewall_arn" {
  value = module.firewall.firewall_arn
}

output "it_test_api_endpoint" {
  value = module.it_api.it_test_api_endpoint_R53alias
}
output "app1_vpc_host_ip" {
  value = aws_instance.app1_vpc_host.private_ip
}

output "integration_vpc_host_ip" {
  value = aws_instance.integration_vpc_host.private_ip
}

output "app_nlb_dns_name" {
  value = aws_lb.app_nlb.dns_name
}

output "ingressegress_vpc_id" {
  value = aws_vpc.ingressegress_vpc.id
}

output "ingressegress_vpc_public_subnet_ids" {
  value = aws_subnet.ingressegress_vpc_public_subnet[*].id
}

# For testing 
#firewall sync states
output "firewall_sync_states" {
  value = module.firewall.firewall_sync_states
}