resource "aws_lb_target_group" "webui" {
  name = "${var.name_prefix}-webui"
  port = 8080
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    path = "/health"
  }
}

resource "aws_lb_target_group_attachment" "webui" {
  target_group_arn = aws_lb_target_group.webui.arn
  target_id = var.bastion_instance_id
}

resource "aws_lb_listener" "webui" {
  load_balancer_arn = var.alb_arn
  port = 8080

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.webui.arn
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_to_alb" {
  security_group_id = var.alb_security_group_id
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_ipv4 = "${var.bastion_public_ip}/32"
}