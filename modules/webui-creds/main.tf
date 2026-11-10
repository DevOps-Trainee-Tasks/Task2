resource "aws_secretsmanager_secret" "webui" {
  name_prefix = "${var.name_prefix}/webui-"
}

resource "aws_secretsmanager_secret_version" "webui" {
  secret_id = aws_secretsmanager_secret.webui.id

  secret_string = jsonencode({
    db_username = var.db_username
    db_password = var.db_password
    webui_secret_key = var.webui_secret_key
  })
}
