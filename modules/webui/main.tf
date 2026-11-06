resource "aws_vpc_security_group_ingress_rule" "webui_to_ollama" {
  security_group_id = var.alb_security_group_id
  ip_protocol = "tcp"
  from_port = 11434
  to_port = 11434
  cidr_ipv4 = "${var.bastion_public_ip}/32"
}