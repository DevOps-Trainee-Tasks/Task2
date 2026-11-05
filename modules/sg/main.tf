resource "aws_security_group" "security_groups" {
  for_each = var.security_groups

  name = each.key
  vpc_id = var.main_vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = {
    for rule in flatten([
      for group_name, group in var.security_groups : [
        for port in group.ingress_ports_tcp : [
          for cidr in group.allowed_cidr_blocks : {
            key = "${group_name}:${port}:${cidr}"
            group_name = group_name
            port = port
            cidr = cidr
          }
        ]
      ]
    ]) : rule.key => rule
  }

  security_group_id = aws_security_group.security_groups[each.value.group_name].id
  ip_protocol = "tcp"
  from_port = each.value.port
  to_port = each.value.port
  cidr_ipv4 = each.value.cidr
}

resource "aws_vpc_security_group_ingress_rule" "security_group" {
  for_each = {
    for rule in flatten([
      for group_name, group in var.security_groups : [
        for port in group.ingress_ports_tcp : [
          for source_group in group.allowed_security_groups : {
            key = "${group_name}:${port}:${source_group}"
            group_name = group_name
            port = port
            source_group = source_group
          }
        ]
      ]
    ]) : rule.key => rule
  }

  security_group_id = aws_security_group.security_groups[each.value.group_name].id
  ip_protocol = "tcp"
  from_port = each.value.port
  to_port = each.value.port
  referenced_security_group_id = aws_security_group.security_groups[each.value.source_group].id
}

resource "aws_vpc_security_group_egress_rule" "egress_rules" {
  for_each = aws_security_group.security_groups

  security_group_id = aws_security_group.security_groups[each.key].id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}
