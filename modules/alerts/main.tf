resource "aws_sns_topic" "monitoring_alerts" {
  name = "${var.name_prefix}-monitoring-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.monitoring_alerts.arn
  protocol = "email"
  endpoint = var.alert_email
}
