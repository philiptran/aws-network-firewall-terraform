output "firewall_arn" {
  value = aws_networkfirewall_firewall.inspection_vpc_anfw.arn
}

output "firewall_sync_states" {
  value = tolist(aws_networkfirewall_firewall.inspection_vpc_anfw.firewall_status[0].sync_states)
}
