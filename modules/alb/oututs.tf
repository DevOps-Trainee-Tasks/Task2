output "target_group_arn" {
  value = aws_lb_target_group.lb_target_group.arn
}

output "webui_target_group_arn" {
  value = aws_lb_target_group.webui.arn
}

output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "arn_suffix" {
  value = aws_lb.alb.arn_suffix
}