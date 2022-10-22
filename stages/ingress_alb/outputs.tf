output "ingress_alb_arn" {
  description = "ARN of Ingress ALB"
  value = aws_alb.ingress_alb.arn
}
output "ingress_alb_id" {
  description = "ID of the ALB"
  value = aws_alb.ingress_alb.id
}

output "ingress_alb_dns_name" {
  description = "DNS name of the ingress ALB"
  value = aws_alb.ingress_alb.dns_name
}
