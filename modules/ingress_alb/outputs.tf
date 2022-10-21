output "ingress_alb" {
  description = "Ingress ALB"
  value = aws_alb.ingress_alb
}
output "ingress_alb_id" {
  description = "ID of the ALB"
  value = aws_alb.ingress_alb.id
}

output "ingress_alb_dns_name" {
  description = "DNS name of the ingress ALB"
  value = aws_alb.ingress_alb.dns_name
}

output "ingress_alb_tg_attachments" {
  description = "ARNs of the target group attachment IDs"
  value = {
    for k, v in aws_alb_target_group_attachment.ingress_alb_tg_targets : k => v.id
  }
}