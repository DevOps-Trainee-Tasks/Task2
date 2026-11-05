resource "aws_lb_target_group_attachment" "webui" {
  target_group_arn = var.webui_target_group_arn
  target_id = var.bastion_instance_id
}

resource "aws_vpc_security_group_ingress_rule" "webui_to_ollama" {
  security_group_id = var.alb_security_group_id
  ip_protocol = "tcp"
  from_port = 11434
  to_port = 11434
  cidr_ipv4 = "${var.bastion_public_ip}/32"
}