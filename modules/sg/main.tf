resource "aws_security_group" "security_groups" {
  for_each = var.security_groups

  name   = each.key
  vpc_id = var.main_vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rules" {
  for_each = {
    for r in flatten([
      for group_name, group in var.security_groups : [
        for rule_name, rule in group.ingress_rules : [
          for port in rule.ports : {
            key          = "${rule_name}:${port}"
            group_name   = group_name
            port         = port
            protocol     = rule.protocol
            cidr_ipv4    = rule.cidr_ipv4
            source_group = rule.source_group
          }
        ]
      ]
    ]) : r.key => r
  }

  security_group_id            = aws_security_group.security_groups[each.value.group_name].id
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.port
  to_port                      = each.value.port
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.source_group == null ? null : aws_security_group.security_groups[each.value.source_group].id
}

resource "aws_vpc_security_group_egress_rule" "egress_rules" {
  for_each = aws_security_group.security_groups

  security_group_id = aws_security_group.security_groups[each.key].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
