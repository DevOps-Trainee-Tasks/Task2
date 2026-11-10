output "address" {
  value = aws_db_instance.rds.address
}

output "master_secret_arn" {
  value = aws_db_instance.rds.master_user_secret[0].secret_arn
}