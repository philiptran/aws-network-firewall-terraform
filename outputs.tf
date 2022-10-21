output "ingress_alb_dns_name" {
  description = "DNS name of the Ingress ALB"
  value = module.ingress_alb.ingress_alb_dns_name
}

output "ingress_alb" {
  value = module.ingress_alb.ingress_alb
}

output "it_test_api_endpoint" {
  value = module.it_api.it_test_api_endpoint_R53alias
}
